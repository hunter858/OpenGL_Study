//
//  RenderView.m
//  OpenGL
//
//  Created by pengchao on 2022/1/7.
//

#import "RenderView.h"
#import <GLKit/GLKit.h>

GLfloat vertices[]  = {
    -0.5f, -0.5f, -1.0f,
    0.0f, 0.5f, -1.0f,
    0.5f, -0.5f, -1.0f,
};

GLfloat colors[] = {
    1.0,0.0,0.0, 1.0,   //red
    0.0,1.0,0.0, 1.0,   //gree
    0.0,0.0,1.0, 1.0    //blue
};



@interface RenderView ()
{
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLint _framebufferWidth;
    GLint _framebufferHeight;
    EAGLContext *_currentContext;
    GLKBaseEffect *_baseEffect;
    CAEAGLLayer *_eaglLayer;
}
@end

@implementation RenderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        _eaglLayer = [[CAEAGLLayer  alloc]init];
        _eaglLayer.frame = frame;
        _eaglLayer.opaque = YES;
        _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:YES],kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
        _baseEffect = [[GLKBaseEffect alloc]init];
        [EAGLContext setCurrentContext:_currentContext];
        [self.layer addSublayer:_eaglLayer];
        [self setupBaseEffect];
        [self setupFrameBuffer];
    }
    return self;
}

- (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupBaseEffect {
    _baseEffect.useConstantColor = GL_TRUE; ///
    _baseEffect.constantColor = GLKVector4Make(1.0, 0, 0, 1.0); ///
    _baseEffect.colorMaterialEnabled = GL_TRUE;
}

- (void)setupFrameBuffer {
    
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    
    /// 填充定点
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT)*3, vertices);
   
    
    /// 填充颜色
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT)*4, colors);
    
    //将相关buffer 依附到帧缓存上；
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    [_currentContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_framebufferWidth);
       glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_framebufferHeight);

    
   
}


-(void)drawRect:(CGRect)rect {
    
    NSLog(@"rect {w:%f,h:%f}",rect.size.width,rect.size.height);
    _eaglLayer.frame = rect;
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glViewport(0, 0, _framebufferWidth, _framebufferHeight);
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [_baseEffect prepareToDraw];
    
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
    glBindRenderbuffer(GL_RENDERBUFFER,_renderBuffer);
    [_currentContext presentRenderbuffer:GL_RENDERBUFFER];
}


- (void)layoutSubviews {
    _eaglLayer.frame = CGRectMake(0, 0, self.frame.size.width,  self.frame.size.height);
}


@end
