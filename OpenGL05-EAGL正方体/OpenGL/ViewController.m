//
//  ViewController.m
//  OpenGL
//
//  Created by pengchao on 2022/1/7.
//

#import "ViewController.h"
#import "RenderView.h"
@interface ViewController ()
@property (nonatomic,strong) RenderView *renderView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _renderView = [[RenderView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:_renderView];
}
@end
