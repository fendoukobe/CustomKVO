//
//  Movie.h
//  CustomKVO
//
//  Created by apple on 16/12/20.
//  Copyright © 2016年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Movie : NSObject
@property (nonatomic,assign) NSNumber* ticketCount;
@property (nonatomic,assign) unsigned int price;
@property (nonatomic,copy) NSString *movieName;
@end
