//
//  CCViewController.m
//  001--GLSL
//
//  Created by CC老师 on 2017/12/16.
//  Copyright © 2017年 CC老师. All rights reserved.
//

#import "CCViewController.h"
#import "CCView.h"
@interface CCViewController ()

@property(nonnull,strong) CCView *myView;
@property (weak, nonatomic) IBOutlet UISlider *slider_x;
@property (weak, nonatomic) IBOutlet UISlider *slider_y;
@property (weak, nonatomic) IBOutlet UISlider *slider_z;

@end

@implementation CCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.myView = [[CCView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:self.myView];
    [self.view sendSubviewToBack:self.myView];


    [self.slider_x addTarget:self action:@selector(change_x:) forControlEvents:UIControlEventValueChanged];
    
    [self.slider_y addTarget:self action:@selector(change_y:) forControlEvents:UIControlEventValueChanged];
    
    [self.slider_z addTarget:self action:@selector(change_z:) forControlEvents:UIControlEventValueChanged];
    
}


- (void)change_x:(UISlider *)slider{
    CGFloat value = slider.value;
    self.myView.roate_x = value;
}

- (void)change_y:(UISlider *)slider{
    CGFloat value = slider.value;
    self.myView.roate_y = value;
}

- (void)change_z:(UISlider *)slider{
    CGFloat value = slider.value;
    self.myView.roate_z = value;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.myView renderLayer];
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
