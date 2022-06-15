//
//  ViewController.m
//  GLSLDemo
//
//  Created by AceDong on 2020/8/28.
//  Copyright © 2020 AceDong. All rights reserved.
//

#import "ViewController.h"
#import "GLSLDemoView.h"

@interface ViewController ()

@property (nonatomic,strong)GLSLDemoView *glDemoView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.glDemoView];
    [self.view sendSubviewToBack:self.glDemoView];
}

- (IBAction)x_value_change:(id)sender {
    
    UISlider *slider = (UISlider *)sender;
    CGFloat  value =  180 * slider.value;
    self.glDemoView.x = value;
}

- (IBAction)y_value_change:(id)sender {
    
    UISlider *slider = (UISlider *)sender;
    CGFloat  value =  180 * slider.value;
    self.glDemoView.y = value;
}
- (IBAction)z_value_change:(id)sender {
    UISlider *slider = (UISlider *)sender;
    CGFloat  value =  180 * slider.value;
    self.glDemoView.z = value;
}

- (GLSLDemoView *)glDemoView{
    if (!_glDemoView) {
        _glDemoView = [[GLSLDemoView alloc] initWithFrame: self.view.frame];
    }
    return _glDemoView;
}



@end
