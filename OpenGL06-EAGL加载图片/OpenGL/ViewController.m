//
//  ViewController.m
//  OpenGL
//
//  Created by pengchao on 2022/1/7.
//

#import "ViewController.h"
#import "RenderView.h"

@interface ViewController ()
@property (nonatomic,strong)  UIImageView * imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    RenderView *renderView = [[RenderView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:renderView];
    


    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    

}

@end
