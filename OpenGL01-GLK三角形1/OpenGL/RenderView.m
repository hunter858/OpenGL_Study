//
//  RenderView.m
//  OpenGL
//
//  Created by pengchao on 2022/1/7.
//
#import <GLKit/GLKit.h>
#import "RenderView.h"

const GLchar *fragment_fsh = (const GLchar *)
"varying lowp vec4 colorVarying;"
"void main()"
"{"
"gl_FragColor = vec4(1, 0, 0, 1);"
"}";


const GLchar *vertex_vsh = (const GLchar *)
"attribute vec3 a_Position;"
"void main(void) {"
"gl_Position = vec4(a_Position, 1.0);"
"}";

CGFloat vertices[]  = {
    -0.5f,0.5f,0.0f,
    -0.5f,-0.5f,0.0f,
    0.5f,-0.5f,0.0f,
};

CGFloat colorTexts[]  = {
    1.0, 0.0, 0.0, 1.0,
    0.0, 1.0, 0.0, 1.0,
    0.0, 0.0, 1.0, 1.0,
};

@interface RenderView ()<GLKViewDelegate>
{
    GLKView *_glkView;
    GLuint _frameBuffer;
    GLuint _colorBuffer;
    GLuint _program;
    GLuint _vertexColor;
    EAGLContext *_currentText;
}
@end

@implementation RenderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentText = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _glkView = [[GLKView alloc]initWithFrame:frame context:_currentText];
        [self addSubview:_glkView];
        _glkView.delegate = self;
        /// 设置颜色缓冲区格式
        _glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
        /// 设置深度缓冲区格式
        _glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        [EAGLContext setCurrentContext:_currentText];
        
        [self setupFrameBuffer];
        [self setupColorBuffer];
        [self setupProgram];
    }
    return self;
}

-(void)setupFrameBuffer {
    glGenBuffers(1, &_frameBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _frameBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    /// 三角型的形状
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT)*3, NULL);
}

- (void)setupColorBuffer {
    glGenRenderbuffers(1, &_colorBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _colorBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(colorTexts), colorTexts, GL_STATIC_DRAW);
    /// 三角型的颜色
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GL_FLOAT)*3, NULL);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorBuffer);
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
        NSLog(@"%@", messageString);
    }
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    
}
- (void)display{
    [_glkView display];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    [EAGLContext setCurrentContext:_currentText];
    CGFloat width = view.frame.size.width;
    CGFloat height = view.frame.size.height;
    glViewport(0, 0, width,height);
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(_program);

    
    GLuint position = glGetAttribLocation(_program, "position");
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 3, NULL);
    glEnableVertexAttribArray(position);
    
    glBindBuffer(GL_ARRAY_BUFFER, _frameBuffer);
//    glEnableVertexAttribArray(0);
//    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    glDrawArrays(GL_TRIANGLES, 0, 3);
   
}

- (void)layoutSubviews {
    _glkView.frame = CGRectMake(0, 0, self.frame.size.width,  self.frame.size.height);
}

- (void)sendPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


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
