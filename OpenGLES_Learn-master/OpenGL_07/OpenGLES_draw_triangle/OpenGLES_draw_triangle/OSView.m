//
//  OSView.m
//  OpenGLES_draw_triangle
//
//  Created by xu jie on 16/8/1.
//  Copyright © 2016年 xujie. All rights reserved.
//
/**
 *  学习目标－ 使用opengl 绘制一个三角形(opengl 图像绘制的软件接口，运行在GPU中，处理矢量运算速度很快)
 *  OpenGL ES 有啥用？主要用在游戏开发(别傻了，难度太大) 和 图像处理,视频实时处理运算等
 *  好了，三角型在opengl 中有很重要的作用，以后说，现在说一下实现思路！
 *  步骤1. 创建一个 CAEAGLayer对象 显示opengl的最终呈现的内容
 *  步骤2. 创建一个EAGLContext 对象管理openGL显示的内容
 *  步骤3. 创建一个帧缓存对象，屏幕刷新时的一帧数据
 *  步骤4. 创建一个颜色渲染缓冲区，用来缓存颜色数据
 *  步骤5. 清除屏幕
 *  步骤6. 创建一个深度渲染缓冲区，用来呈现立体效果图(2D 图像就不要了)
 *  步骤7. 将三角型的三个顶点 加载到GPU中
 *  步骤8. 将三角型的三个顶点的颜色，加载到GPU中去
 *  步骤9. 执行绘图命令
 *  步骤10.呈现到context中去
 *  友情提示.过程有的曲折，希望各位好好理解!坚持就是胜利！有啥问题 群里交流: 578734141
 */
#import "OSView.h"
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>
@interface OSView()
@property(nonatomic,strong)EAGLContext *eagContext;
@property(nonatomic,strong)GLKBaseEffect *baseEffect;
@end
GLfloat vertices [6] =  {-1,1, // 左上
                        -1,-1, // 左下
                        1,-1}; // 右下

GLfloat colors[9] = {1,0,0,  // 左上
                     0,0,1,  // 左下
                     0,1,0}; // 右下

@implementation OSView{
    GLuint _framebuffer; // 帧缓存标示
    GLuint _colorFramebuffer;// 颜色缓存标示
    
    GLuint _positionbuffer; // 顶点坐标标示;
    GLuint _colorbuffer; // 顶点对应的颜色渲染缓冲区标示
}


// MARK: - 步骤1  重写下面的方法，将view的layer层变为 CAEAGLayer 类型 简单的很
+(Class)layerClass{
    
    return [CAEAGLLayer class];
}
// MARK: - 配置layer 暂时没bi
-(void)configure{
    CAEAGLLayer *eagLayer = (CAEAGLLayer *)self.layer;
    eagLayer.opaque = true; // 提高渲染质量 但会消耗内存
    eagLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking : @(false),kEAGLColorFormatRGBA8:@(true)};
    self.baseEffect = [[GLKBaseEffect alloc]init];
    
}

// MARK: - 步骤2  创建一个EAGLContext对象 对象管理openGL加载到GPU的内容  简单的很
-(void)createEAGContext{
    self.eagContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.eagContext];
}
// MARK: - 步骤3  创建一个帧缓存对象
/*
 * 创建帧缓存的步骤
 * 1.申请内存标示
 * 2.绑定
 * 3.开辟内存空间
 */
-(void)createFramebuffer{
    
    glGenFramebuffers(1, &_framebuffer); // 为帧缓存申请一个内存标示，唯一的 1.代表一个帧缓存
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);// 把这个内存标示绑定到帧缓存上
    
    
}
// MARK: - 步骤4  创建颜色渲染缓存
/*
 * 创建帧缓存的步骤
 * 1.申请内存标示
 * 2.绑定
 * 3.设置帧缓存的颜色渲染缓存地址
 * 4.开辟内存空间
 */
- (void)createColorRenderbuffer{
    glGenRenderbuffers(1, &_colorFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorFramebuffer);
    [self.eagContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,GL_RENDERBUFFER, _colorFramebuffer);
    
}
// MARK: - 步骤五 清除屏幕
/*
 * 1. 设置清除屏幕的颜色
 * 2. 清除屏幕 GL_COLOR_BUFFER_BIT 代表颜色缓冲区
 */
- (void)clear{
    glViewport(0, 0, [self drawableWidth], [self drawableHeight]);
    glClearColor(1, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
}
// MARK: 步骤六 - 绘制三角型顶点
-(void) createTriangleVertices{
     [self.baseEffect prepareToDraw];
    glGenBuffers(1, &_positionbuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _positionbuffer);
    glBufferData(GL_ARRAY_BUFFER,  sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    // 设置指针
    glVertexAttribPointer(GLKVertexAttribPosition, // 指示绑定的缓存包含的是顶点位置的信息
                          3,// 顶点数量
                          GL_FLOAT, // 数据类型
                          GL_FALSE,// 告诉opengl 小数点固定数据是否可以被改变
                          sizeof(GLfloat)*2, // 步幅 指定每个顶点保存需要多少个字节
                          NULL); // 告诉opengl 可以从绑定数据的开始位置访问数据
    
    // 绘图
    glDrawArrays(GL_TRIANGLES, // 告诉opengl 怎么处理顶点缓存数据
                 0, // 设置绘制第一个顶点的位置
                 3); // 绘制顶点的数量
    
 
 
}
// MARK: 步骤七 - 创建顶点颜色渲染缓冲区
/*
 * 步骤1 申请内存标示
 * 步骤2 绑定
 * 步骤3 将颜色数据加入gpu的内存中
 * 步骤4 启动绘制颜色命令
 * 步骤5 设置绘图配置
 * 步骤6 开始绘制
 */
-(void)createColorbuffer{
    [self.baseEffect prepareToDraw];
    glGenBuffers(1, &_colorbuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _colorbuffer);
    glBufferData(GL_ARRAY_BUFFER,  sizeof(colors), colors, GL_STATIC_DRAW);
    
    // 启动绘制颜色命令
    glEnableVertexAttribArray(GLKVertexAttribColor);
    
    // 设置指针
    glVertexAttribPointer(GLKVertexAttribColor, // 指示绑定的缓存包含的是顶点位置的信息
                          3,// 顶点数量
                          GL_FLOAT, // 数据类型
                          GL_FALSE,// 告诉opengl 小数点固定数据是否可以被改变
                          sizeof(GLfloat)*3, // 步幅 指定每个顶点保存需要多少个字节
                          NULL); // 告诉opengl 可以从绑定数据的开始位置访问数据
    // 绘图
    glDrawArrays(GL_TRIANGLES, // 告诉opengl 怎么处理顶点缓存数据
                 0, // 设置绘制第一个顶点的位置
                 3); // 绘制顶点的数量

}

// MARK: 步骤八 将渲染缓存中的内容呈现到视图中去
-(void)showRenderbuffer{
      [self.eagContext  presentRenderbuffer:GL_RENDERBUFFER];
}

// 执行步骤
-(void)setupGL{
    [self configure];
    [self createEAGContext];// 2
    [self createFramebuffer];// 3
    [self createColorRenderbuffer];//4
    [self clear];//5
    [self createTriangleVertices]; // 6
    [self createColorbuffer]; // 7
    [self showRenderbuffer];//9
    
    
}

-(GLint)drawableWidth{
    GLint width;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    return width;
}
-(GLint)drawableHeight{
    GLint height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    return height;
}

- (void)willMoveToSuperview:(UIView *)newSuperview{
    [super willMoveToSuperview:newSuperview];
    [self setupGL];
}


@end
