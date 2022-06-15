//
//  ViewController.m
//  OpenGL
//
//  Created by pengchao on 2022/1/7.
//

#import "ViewController.h"

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    /*
     画一个三角形
     */
    RenderView *renderView = [[RenderView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:renderView];
}



@end
