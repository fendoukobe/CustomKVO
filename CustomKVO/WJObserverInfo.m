//
//  WJObserverInfo.m
//  CustomKVO
//
//  Created by apple on 16/12/20.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "WJObserverInfo.h"

@implementation WJObserverInfo
- (instancetype)initWithObserVer:(id)observer key:(NSString *)key callback:(WJKVOCallback)callback{
    self = [super init];
    if(self){
        _observer = observer;
        _key = key;
        _callback = callback;
    }
    return self;
}
@end
