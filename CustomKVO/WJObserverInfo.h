//
//  WJObserverInfo.h
//  CustomKVO
//
//  Created by apple on 16/12/20.
//  Copyright © 2016年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^WJKVOCallback)(id observer,NSString *key,id oldValue,id newValue);

@interface WJObserverInfo : NSObject

@property (nonatomic,weak) id observer;//监听者
@property (nonatomic,copy) NSString *key;//监听的属性
@property (nonatomic,copy) WJKVOCallback callback;//回调的block

- (instancetype)initWithObserVer:(id)observer key:(NSString *)key callback:(WJKVOCallback)callback;
@end
