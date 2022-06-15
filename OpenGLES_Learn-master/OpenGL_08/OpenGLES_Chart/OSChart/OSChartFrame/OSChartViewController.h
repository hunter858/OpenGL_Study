//
//  GameViewController.h
//  OSChart
//
//  Created by xu jie on 16/8/15.
//  Copyright © 2016年 xujie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface OSChartViewController : GLKViewController

- (void)loadData:(NSArray*)data;
-(instancetype)initWithChartData:(NSArray*)chartData;
- (void)startRotation;
- (void)stopRotation;
@end
