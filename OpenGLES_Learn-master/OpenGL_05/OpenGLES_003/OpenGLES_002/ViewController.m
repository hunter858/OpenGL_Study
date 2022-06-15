//
//  ViewController.m
//  OpenGLES_002
//
//  Created by xu jie on 16/8/6.
//  Copyright © 2016年 xujie. All rights reserved.
//
/*
 *  学习目标 使用OpenGL ES 绘制一个移动的正方形
 *  步骤1: 创建一个 GLKViewController
 *  步骤2: 创建一个EAGContext 跟踪我们所有的特定的状态，命令和资源
 *  步骤3: 清除屏幕
 *  步骤4: 创建投影坐标系
 *  步骤5: 创建物体自身坐标系
 *  步骤6: 加载定点数据
 *  步骤7: 加载颜色数据
 *  步骤8: 开始绘制
 */

#import "ViewController.h"
#import "os_square.h" // 存放定点坐标 和 颜色值
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface ViewController ()
@property(nonatomic,strong) EAGLContext *eagContex;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createEagContext]; // 2
    [self configure];
}

/**
 *  创建EAGContext
 */
- (void)createEagContext{
    self.eagContex = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES1];
    [EAGLContext setCurrentContext:self.eagContex];
}

/**
 *  配置view
 */
-(void)configure{
    GLKView *view = (GLKView*)self.view;
    view.context = self.eagContex;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
}
/**
 *  清除屏幕
 */
-(void)clear{
    glClearColor(1, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);
}

/**
 *  创建投影坐标
 */
-(void)initProjectionMatrix{
    glMatrixMode(GL_PROJECTION); // 设置投影模式
    glLoadIdentity(); // 导入
}
/**
 *  创建自身坐标
 */
-(void)initModelView:(int)count{
     static float transY = 0.0;
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glTranslatef(0.0, (GLfloat)(sinf(transY)/2.0), 0.0);
    
    if (count %100 ==0) {
       
        transY +=10 ;
    } else {
        transY = 0;
    }
}

/**
 *  加载顶点数据
 */
-(void)loadVetexData{
    glVertexPointer(2, GL_FLOAT, 0, squareVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    
}

/**
 *  加载颜色数据
 */
-(void)loadColorData{
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, squareColors2);
    glEnableClientState(GL_COLOR_ARRAY);
}

/**
 *  开始绘制
 */
-(void)draw{
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}


-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    
    static int count = 0;
    [self clear]; //3
    [self initProjectionMatrix]; //4
    [self initModelView:count];//5
    [self loadVetexData];//6
    [self loadColorData];//7
    [self draw];//8

    count ++;
}










@end
