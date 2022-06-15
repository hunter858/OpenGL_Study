//
//  GameViewController.m
//  OpenGL_draw_square
//
//  Created by xu jie on 16/8/4.
//  Copyright © 2016年 xujie. All rights reserved.
//

#import "GameViewController.h"
#import <OpenGLES/ES2/glext.h>
#import "os_cube.h"

/*
 * 学习目标 简单的绘制一个立方体
 * 亮点 :使用系统封装好的对象来做 代码简洁，好维护
 * 实现步骤:
 * 第一步 .创建一个继承 GLKViewController(为我们封装了好多代码)的对象
 * 第二步 .创建一个EAGLContext 对象负责管理gpu的内存和指令
 * 第三步 .创建一个GLKBaseEffect 对象，负责管理渲染工作
 * 第四步 .创建立方体的顶点坐标和法线
 * 第五步 .绘图
 * 第六步 .让立方体运动其它
 * 第七步 .在视图消失的时候，做一些清理工作
 */
 // 加群 ：578734141 学习

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface GameViewController () {
    float _rotation;
    GLuint _vertexBuffer;
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;



@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createEAGContext];// 1. 创建管理上下文
    [self configure]; // 2.配置
    [self createBaseEffect]; // 3.创建渲染管理
    [self addVertexAndNormal]; // 4.添加顶点坐标和法线坐标

}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self clearScreen]; // 5.清理屏幕
    [self draw]; //.6 绘制
    
    
    
}

- (void)update
{
    [self changeMoveTrack]; // 7.移动
}

- (void)dealloc
{
    [self tearDownGL]; // 8.清理工作
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}



// MARK: - 配置
-(void) configure{
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
}
// MARK: - 第一步: 创建一个EAGLContext

-(void)createEAGContext{
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"手机不支持opengl es2");
    }
    
     [EAGLContext setCurrentContext:self.context]; // 设置为当前上下文

}
// MARK: - 第二步: 创建GLKBaseEffect 对象
-(void)createBaseEffect{
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(0.5f, 0.1f, 0.4f, 1.0f);
}

// MARK: - 第三步:
- (void)addVertexAndNormal{
    glEnable(GL_DEPTH_TEST); // 开启深度测试 让被挡住的像素隐藏
    
    // 讲顶点数据和法线数据加载到GUP 中去
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
    
    // 开启绘制命令 GLKVertexAttribPosition(位置)
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, 0);
    
    // 开启绘制命令 GLKVertexAttribPosition(法线)
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
}

// MARK: - 第四步: 清屏
- (void)clearScreen{
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

// MARK: - 第五步: 绘制
- (void)draw{
    [self.effect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, 36);
}

// MARK: - 第六步: 改变运动轨迹

- (void)changeMoveTrack{
    // 获取一个屏幕比例值
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    
    //  GLKMatrix4MakePerspective(float fovyRadians, float aspect, float nearZ, float farZ)
    /*
     * 透视转换
     */
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -10.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    // 计算自身的坐标和旋转状态
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    self.effect.transform.modelviewMatrix = modelViewMatrix;
    _rotation += self.timeSinceLastUpdate * 0.5f;
}

// MARK: - 第七步: 清楚工作
- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    glDeleteBuffers(1, &_vertexBuffer);
    self.effect = nil;

}






- (BOOL)prefersStatusBarHidden {
    return YES;
}









@end
