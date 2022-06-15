//
//  RenderView.m
//  OpenGL
//
//  Created by pengchao on 2022/1/7.
//
#import <GLKit/GLKit.h>
#import "RenderView.h"

typedef struct {
   GLKVector3  positionCoords;
}
SceneVertex;

/////////////////////////////////////////////////////////////////
// Define vertex data for a triangle to use in example
static const SceneVertex vertices[] =
{
   {{-0.5f, -0.5f, 0.0}}, // lower left corner
   {{ 0.5f, -0.5f, 0.0}}, // lower right corner
   {{-0.5f,  0.5f, 0.0}}  // upper left corner
};
//
CGFloat vertices2[]  = {
     -0.5f,-0.5f,0,
    0.5f,-0.5f,0,
    0.5f,0.5f,0
//    0,0,-0.5,
};

@interface RenderView () <GLKViewDelegate>
{
    GLKView *_glkView;
    GLuint _frameBuffer;
    EAGLContext *_currentText;
    GLKBaseEffect *_baseEffect;
}
@end

@implementation RenderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentText = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _glkView = [[GLKView alloc]initWithFrame:frame context:_currentText];
        _glkView.context = _currentText;
        [self addSubview:_glkView];
        _baseEffect = [[GLKBaseEffect alloc]init];
        _glkView.delegate = self;
        /// 设置颜色缓冲区格式
        _glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
        /// 设置深度缓冲区格式
        _glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        [EAGLContext setCurrentContext:_currentText];

        [self setupBaseEffect];
        [self setupFrameBuffer];
    }
    return self;
}

- (void)setupBaseEffect {
    _baseEffect.useConstantColor = GL_TRUE; ///
    _baseEffect.constantColor = GLKVector4Make(1.0, 0, 0, 1.0); ///
    _baseEffect.colorMaterialEnabled = GL_TRUE;
}

- (void)setupFrameBuffer {
    glGenBuffers(1, &_frameBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _frameBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    [_baseEffect prepareToDraw];
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    /// 开启缓存
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    /// 设置缓存数据指针
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT)*3, NULL);
    glDrawArrays(GL_TRIANGLES, 0,3);
}

- (void)layoutSubviews {
    _glkView.frame = CGRectMake(0, 0, self.frame.size.width,  self.frame.size.height);
}


@end
