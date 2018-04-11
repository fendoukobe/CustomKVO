//
//  ViewController.m
//  CustomKVO
//
//  Created by apple on 16/12/19.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "ViewController.h"
#import "Movie.h"

#import "NSObject+WJ_KVO.h"
#import "WJObserverInfo.h"

@interface ViewController ()
@property (nonatomic,strong) Movie *movie;
@property (nonatomic,strong) UILabel *label;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.movie = [[Movie alloc] init];
    self.movie.ticketCount = @(100);
    self.movie.price = 60;
    self.movie.movieName = @"三少爷的剑";
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setBackgroundColor:[UIColor redColor]];
    btn.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - 100)/2, 100, 100, 30);
    [btn setTitle:@"售票" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.frame = CGRectMake(0, 150, [UIScreen mainScreen].bounds.size.width, 30);
    label.text = [NSString stringWithFormat:@"当前还剩 %d 张票 ",[self.movie.ticketCount intValue]];
    self.label = label;
    [self.view addSubview:label];
    
   [self.movie wj_addObserver:label key:@"ticketCount" callback:^(UILabel *observerLabel, NSString *key, id oldValue, id newValue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            observerLabel.text = [NSString stringWithFormat:@"当前还剩 %d 张票 ",[self.movie.ticketCount intValue]];
        });
    }];
}

- (void)btnClick{
    self.movie.ticketCount = @([self.movie.ticketCount intValue] - 1);
}
- (void)dealloc{
    //移除监听
    [self.movie wj_removeObserver:self key:@"ticketCount"];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
