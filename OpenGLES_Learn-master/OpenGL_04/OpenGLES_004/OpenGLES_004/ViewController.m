//
//  ViewController.m
//  OpenGLES_004
//
//  Created by xu jie on 16/8/6.
//  Copyright © 2016年 xujie. All rights reserved.
//
/**
 *  学习目标
 *
 *  第一步: 创建GLKViewController 控制器(在里面实现方法)
 *  第二步: 创建EAGContext 跟踪所有状态,命令和资源
 *  第三步: 清除命令
 *  第四步: 创建投影坐标系
 *  第五步: 创建对象坐标
 *  第六步: 导入顶点数据
 *  第七步: 导入颜色数据
 *  第八步: 绘制
 *  欢迎加群: 578734141 交流学习~
 *
 */
#import "ViewController.h"
#import "os_cube.h"
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES1/gl.h>

@interface ViewController ()
@property(nonatomic,strong)EAGLContext *eagContext;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createEagContext];
    [self configure];
    [self setClipping];
    
}
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    [self clear];
    [self initModelViewMatrix];
    [self loadVertexData];
    [self loadColorBuffer];
    [self draw];
}


/**
 *  创建EAGContext 跟踪所有状态,命令和资源
 */
- (void)createEagContext{
    self.eagContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES1];
    [EAGLContext setCurrentContext:self.eagContext];
}
/**
 *  配置view
 */

- (void)configure{
    GLKView *view = (GLKView*)self.view;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.context = self.eagContext;
    
}

/**
 *  清除
 */
-(void)clear{
    glEnable(GL_DEPTH_TEST);
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
}

/**
 *  创建投影坐标
 */
- (void)initProjectionMatrix{
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
}

/**
 *  创建物体坐标
 */

-(void)initModelViewMatrix{
  
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    static GLfloat transY = 0.0;
    static GLfloat z=-2.0;
				//1
    static GLfloat spinX=0;
    static GLfloat spinY=0;
    glTranslatef(0.0, (GLfloat)(sinf(transY)/2.0), z);
    glRotatef(spinY, 0.0, 1.0, 0.0);
    glRotatef(spinX, 1.0, 0.0, 0.0);
    transY += 0.075f;
    spinY+=.25;
    spinX+=.25;
}
/**
 *  导出顶点坐标
 *  glVertexPointer 第一个参数:每个顶点数据的个数,第二个参数,顶点数据的数据类型,第三个偏移量，第四个顶点数组地址
 */
- (void)loadVertexData{
    glVertexPointer(3, GL_FLOAT, 0, cubeVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
}

/**
 *  导入颜色数据
 */
- (void)loadColorBuffer{
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, cubeColors);
    glEnableClientState(GL_COLOR_ARRAY);
}

/**
 *  导入索引数据
 */
-(void)draw{
    // 开启剔除面功能
    glEnable(GL_CULL_FACE);                                                             //3
    glCullFace(GL_BACK); // 剔除背面
    glDrawElements( GL_TRIANGLE_FAN, 18, GL_UNSIGNED_BYTE, tfan1);
    glDrawElements( GL_TRIANGLE_FAN, 18, GL_UNSIGNED_BYTE, tfan2);
}

/**
 *  设置窗口及投影坐标的位置
 */
-(void)setClipping
{
    float aspectRatio;
    const float zNear = .1;                                                         //1
    const float zFar = 1000;                                                        //2
    const float fieldOfView = 60.0;                                                 //3
    GLfloat    size;
    CGRect frame = [[UIScreen mainScreen] bounds];                                  //4
  
    aspectRatio=(float)frame.size.width/(float)frame.size.height;                   //5
    [self initProjectionMatrix];
    size = zNear * tanf(GLKMathDegreesToRadians (fieldOfView) / 2.0);
    // 设置视图窗口的大小 和 坐标系统
    glFrustumf(-size, size, -size /aspectRatio, size /aspectRatio, zNear, zFar);    //8
    glViewport(0, 0, frame.size.width, frame.size.height);                          //9

}




@end
