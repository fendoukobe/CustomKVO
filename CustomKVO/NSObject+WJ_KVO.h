//
//  NSObject+WJ_KVO.h
//  CustomKVO
//
//  Created by apple on 16/12/19.
//  Copyright © 2016年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WJObserverInfo.h"

@interface NSObject (WJ_KVO)

- (void)wj_addObserver:(id)observer key:(NSString *)key callback:(WJKVOCallback)callback;
- (void)wj_removeObserver:(id)observer key:(NSString *)key;

@end
