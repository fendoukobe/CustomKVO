//
//  NSObject+WJ_KVO.m
//  CustomKVO
//
//  Created by apple on 16/12/19.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "NSObject+WJ_KVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

#define WJKVOClassPrefix @"WJKVO_"
#define WJAssociateArrayKey @"WJAssociateArrayKey"

/**
 假设被观察者为A类的实例L，实现流程如下：
 1.在运行时，为A类创建一个子类B。
 2.强行将实例L的类型改为B。
 3.为B类添加新的setter方法。
 4.为B类添加观察者列表属性M。
 5.将观察者的信息封装为类放入B类的M。
 
 
 重点在第三项——kvo的setter方法如何写：
 因为是将实例L的类更改为了原类A的子类B，需要调用父类的对应的setter方法。
 由于在整个KVO过程中，观察的属性不一致则setter方法的名字也不一致。无法直接运用super调用，最简单的方法就是通过runtime来实现。
 1. 获得setter方法名
 2. 根据setter方法名获得对应的setter消息
 3. 根据setter方法名获得getter方法名
 4. 根据getter方法名获得被观察属性当前值
 5. 创建消息传递结构体（为了把setter消息转发给父类）
 6. 把setter消息转发给父类
 7. 遍历观察者列表，得到观察者信息，执行操作
 */

@implementation NSObject (WJ_KVO)

- (void)wj_addObserver:(id)observer key:(NSString *)key callback:(WJKVOCallback)callback{
    // 1.检查对象的类有没有相应的setter方法，如果没有抛出异常
    SEL setterSelector = NSSelectorFromString([self setterForGetter:key]);
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    if(!setterMethod){
        NSLog(@"找不到该方法");
        return;
    }
    // 2.检查对象isa 指向的类是不是一个KVO类，如果不是，新建一个继承原来类的子类，并把isa指向新建的子类
    Class clazz = object_getClass(self);
    NSString *className = NSStringFromClass(clazz);
    if(![className hasPrefix:WJKVOClassPrefix]){
        clazz = [self wj_KVOClassWithOriginalClassName:className];
        object_setClass(self, clazz);
    }
    
    // 3.为kvo class添加setter方法的实现
    const char *types = method_getTypeEncoding(setterMethod);
    class_addMethod(clazz, setterSelector, (IMP)wj_setter, types);
    
    // 4.添加该观察者到观察列表中
    // 4.1 创建观察者信息
    WJObserverInfo *info = [[WJObserverInfo alloc] initWithObserVer:observer key:key callback:callback];
    // 4.2 获取关联对象（装着所有监听者的数组）
    NSMutableArray *observers = objc_getAssociatedObject(self, WJAssociateArrayKey);
    if(!observers){
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, WJAssociateArrayKey, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observers addObject:info];
}
- (Class)wj_KVOClassWithOriginalClassName:(NSString *)className{
    NSString *kvoClassName = [WJKVOClassPrefix stringByAppendingString:className];
    Class kvoClass = NSClassFromString(kvoClassName);
    //如果kvoClss 存在就返回
    if(kvoClass){
        return kvoClass;
    }
    //如果不存在，则创建一个
    Class orginClass = object_getClass(self);
    kvoClass = objc_allocateClassPair(orginClass, kvoClassName.UTF8String, 0);
    
    //修改kvo class方法的实现,学习Apple的做法，隐瞒这个kvo_class
    Method clazzMethod = class_getInstanceMethod(kvoClass, @selector(class));
    const char *types = method_getTypeEncoding(clazzMethod);
    class_addMethod(kvoClass, @selector(class), (IMP)wj_class, types);
    objc_registerClassPair(kvoClass);
    
    return kvoClass;
}
/**
 * 模仿Apple的做法，欺骗人们这个KVO类还是原类
 */
Class wj_class(id self,SEL cmd){
    Class clszz = object_getClass(self);
    Class superClazz = class_getSuperclass(clszz);
    return superClazz;
}

/**
 * 重写setter方法，新方法在调用原方法后，通知每个观察者（调用传入的block）
 * 如果监听的不是OC类型的属性，则会闪退
 */
static void wj_setter(id self,SEL _cmd,id newValue){
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = [self getterForSetter:setterName];
    if(!getterName){
        NSLog(@"占不到getter方法");
    }
    // 获取旧值
    id oldValue = [self valueForKey:getterName];
    //调用原来的setter方法
    struct objc_super superClazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    // 父类监听的属性赋值
    ((void (*)(void *,SEL,id))objc_msgSendSuper)(&superClazz,_cmd,newValue);
    //为什么不用下面方法替代上面的方法
    // ((void (*)(id, SEL, id))objc_msgSendSuper)(self, _cmd, newValue);
    
    //找出观察者的数组，调用对应对象的callback
    NSMutableArray *observers = objc_getAssociatedObject(self, WJAssociateArrayKey);
    //遍历数组
    for (WJObserverInfo *info in observers) {
        if([info.key isEqualToString:getterName]){
           //gcd 异步调用callback
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                info.callback(info.observer,info.key,oldValue,newValue);
            });
        }
    }
    
}

- (void)wj_removeObserver:(id)observer key:(NSString *)key{
    NSMutableArray *observers = objc_getAssociatedObject(self, WJAssociateArrayKey);
    if(!observers)return;
    for (WJObserverInfo *info in observers) {
        if([info.key isEqualToString:key]){
            [observers removeObject:info];
            break;
        }
    }
}

#pragma mark -私有方法
/**
 * 根据getter方法名返回setter方法名
 */
- (NSString *)setterForGetter:(NSString *)key{
    //name -> Name -> setName:
    // 1.首字母大写
    UniChar c = [key characterAtIndex:0];
    NSString *str = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[NSString stringWithFormat:@"%c",c-32]];
    // 2.最前面加set,最后增加:
    NSString *setter = [NSString stringWithFormat:@"set%@:",str];
    
    return setter;
}
/**
 * 根据setter方法名返回getter方法名
 */
- (NSString *)getterForSetter:(NSString *)key{
    // setName -> Name -> name
    // 1.去掉set
    NSRange range = [key rangeOfString:@"set"];
    NSString *subStr1 = [key substringFromIndex:range.location+range.length];
    // 2.首字母换成小写
    unichar c = [subStr1 characterAtIndex:0];
    NSString *subStr2 = [subStr1 stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[NSString stringWithFormat:@"%c",c+32]];
    // 3.去掉：
    NSRange range1 = [subStr2 rangeOfString:@":"];
    NSString *getter = [subStr2 substringToIndex:range1.location];
    return  getter;
}

@end
