//
//  CCViewController.m
//  001--GLSL
//
//  Created by CC老师 on 2017/12/16.
//  Copyright © 2017年 CC老师. All rights reserved.
//

#import "CCViewController.h"
#import "CCView.h"
#import "CustomImageView.h"
@interface CCViewController ()

@property(nonnull,strong) CCView *myView;
@property(nonnull,strong) CustomImageView *imageView;

@end

@implementation CCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.myView = (CCView *)self.view;
    self.imageView = [[CustomImageView alloc]initWithFrame:self.view.frame];
    self.myView.delegate = self.imageView;
    [self.view addSubview:self.imageView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
