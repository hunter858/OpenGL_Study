//
//  ViewController.m
//  OSChart
//
//  Created by xu jie on 16/8/15.
//  Copyright © 2016年 xujie. All rights reserved.
//

#import "ViewController.h"
#import "OSChartViewController.h"
#import "OSCapture/OSCaptureView.h"
// 欢迎加入群：578734141 探讨技术

@interface ViewController ()
@property(nonatomic,strong) OSChartViewController *chartVC;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 第一步，添加3D 视图
    OSChartViewController *chartVC = [[OSChartViewController alloc]initWithChartData:@[@10,@100,@200,@300,@400]];
    self.chartVC = chartVC;
    chartVC.view.frame = self.view.bounds;
    [self.view insertSubview:chartVC.view atIndex:0];
    [self addChildViewController:chartVC];
    
    // 第二步 打开摄像头
    chartVC.view.backgroundColor = [UIColor clearColor];
    OSCaptureView *view = [[OSCaptureView alloc]init];
    view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    
    [self.view insertSubview:view atIndex:0];
    [view setup:^(CGImageRef image) {
       
    }];
  
    
}

- (IBAction)rotation:(id)sender {
    [self.chartVC startRotation];
}


@end
