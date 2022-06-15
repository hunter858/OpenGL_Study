//
//  ViewController.m
//  OpenGL
//
//  Created by pengchao on 2022/1/7.
//

#import "ViewController.h"
#import "RenderView.h"
#import "RenderView1.h"
#import "RenderView2.h"
#import "RenderView3.h"
#import "RenderView4.h"
#import "RenderView5.h"
#import "RenderView6.h"

@interface ViewController ()
@property (nonatomic,strong)  UIImageView * imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    RenderView *renderView = [[RenderView alloc]initWithFrame:self.view.frame];
//    [self.view addSubview:renderView];
    
    
    ///方法1，将顶点沿z轴旋转180度
//    RenderView1 *render1 = [[RenderView1 alloc]initWithFrame:self.view.frame];
//    [self.view addSubview:render1];
    
//    ///方法2，将原始图片反转
    RenderView2 *render2 = [[RenderView2 alloc]initWithFrame:self.view.frame];
    [self.view addSubview:render2];
    
//    ///方案3-修改片元着色器代码，纹理坐标围绕x轴翻转
//    RenderView3 *render3 = [[RenderView3 alloc]initWithFrame:self.view.frame];
//    [self.view addSubview:render3];

    ///方案4-修改顶点着色器代码 纹理坐标沿x轴翻转
//    RenderView4 *render4 = [[RenderView4 alloc]initWithFrame:self.view.frame];
//    [self.view addSubview:render4];
    
    ///方法5，直接修改纹理坐标数据，让其沿着x轴翻转
    //RenderView5 *render5 = [[RenderView5 alloc]initWithFrame:self.view.frame];
    //[self.view addSubview:render5];
    
    // 方法6，直接修改顶点坐标数据，让其沿着x轴翻转
//    RenderView6 *render6 = [[RenderView6 alloc]initWithFrame:self.view.frame];
//    [self.view addSubview:render6];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    

}

@end
