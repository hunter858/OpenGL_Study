//
//  RenderView.m
//  OpenGL
//
//  Created by pengchao on 2022/1/7.
//
#import "RenderView.h"
#import <GLKit/GLKit.h>

GLfloat vertices[]  = {
    -0.5f,0.5f,0.0f,
    -0.5f,-0.5f,0.0f,
    0.5f,-0.5f,0.0f,
};

GLfloat colorTexts[]  = {
    1.0, 0.0, 0.0, 1.0,
    0.0, 1.0, 0.0, 1.0,
    0.0, 0.0, 1.0, 1.0,
};

@interface RenderView ()
{
    CAEAGLLayer *_eaglLayer;
    GLuint _frameBuffer;
    GLuint _colorBuffer;
    GLuint _program;
    GLuint _vertexColor;
    EAGLContext *_currentContext;
    
    GLint _frameWidth;
    GLint _frameHeight;
}
@end

@implementation RenderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _eaglLayer = [[CAEAGLLayer alloc]init];
        [self.layer addSublayer:_eaglLayer];
        _eaglLayer.frame = frame;
        _eaglLayer.opaque = YES;
        _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:YES],kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
        [EAGLContext setCurrentContext:_currentContext];
        
        [self setupFrameBuffer];
        [self setupColorBuffer];
        [self setupBindFrameBuffer];
        [self setupProgram];
    }
    return self;
}

- (void)layoutSubviews {
    _eaglLayer.frame = CGRectMake(0, 0, self.frame.size.width,  self.frame.size.height);
}


-(void)setupFrameBuffer {
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    /// 三角型的形状
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT)*3, vertices);
}

- (void)setupColorBuffer {
    glGenRenderbuffers(1, &_colorBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBuffer);
    /// 三角型的颜色
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT)*4, colorTexts);
}


- (void)setupBindFrameBuffer {
    ///frameBuffer 和renderBuffer 绑定
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorBuffer);
    [_currentContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
    
    /// 获取渲染的width、height
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_frameWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_frameHeight);
}

- (void)setupProgram {
    GLuint vertexShader = [self loadShaderType:GL_VERTEX_SHADER fileName:@"vertex.vsh"];
    GLuint fragmentShader = [self loadShaderType:GL_FRAGMENT_SHADER fileName:@"fragment.fsh"];
    _program =  glCreateProgram();
    glAttachShader(_program, vertexShader);
    glAttachShader(_program, fragmentShader);
    glLinkProgram(_program);
    
    //检查program结果
    GLint linkSuccess;
    glGetProgramiv(_program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(_program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error message: %@", messageString);
    }
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
}

- (void)drawRect:(CGRect)rect {
   
}


-(void)drawTrangles {
    [EAGLContext setCurrentContext:_currentContext];

    glViewport(0, 0, _frameWidth, _frameHeight);
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(_program);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    [_currentContext presentRenderbuffer:GL_RENDERBUFFER];
}


- (void)sendPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
}

- (GLuint)loadShaderType:(GLenum)type fileName:(NSString *)shaderName {
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:nil];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        return -1;
    }
    
    GLuint shader = glCreateShader(type);
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shader, 1, &shaderStringUTF8, &shaderStringLength);
    glCompileShader(shader);
    ///删除
    GLint status;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shader, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        return -1;
    }
    return shader;
}

@end
