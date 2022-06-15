//
//  RenderView.m
//  OpenGL
//
//  Created by pengchao on 2022/1/7.
//
#import <GLKit/GLKit.h>
#import "RenderView.h"

GLfloat vertices[]  = {
    0.5f, -0.5f, -1.0f,     1.0f, 0.0f, //右下角A
    -0.5f, 0.5f, -1.0f,     0.0f, 1.0f, //左上角B
    -0.5f, -0.5f, -1.0f,    0.0f, 0.0f, //左下角C
    
    0.5f, 0.5f, -1.0f,      1.0f, 1.0f, //右上角D
    -0.5f, 0.5f, -1.0f,     0.0f, 1.0f, //左上角B
    0.5f, -0.5f, -1.0f,     1.0f, 0.0f, //右下角A
};

@interface RenderView ()<GLKViewDelegate>
{
    GLKView *_glkView;
    GLuint _frameBuffer;
    GLuint _colorBuffer;
    GLuint _program;
    GLuint _vertexColor;
    EAGLContext *_currentContext;
}
@end

@implementation RenderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _glkView = [[GLKView alloc]initWithFrame:frame context:_currentContext];
        [self addSubview:_glkView];
        _glkView.delegate = self;
        /// 设置颜色缓冲区格式
        _glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
        /// 设置深度缓冲区格式
        _glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        [EAGLContext setCurrentContext:_currentContext];
        
        [self setupFrameBuffer];
        [self setupProgram];
    }
    return self;
}

- (void)layoutSubviews {
    _glkView.frame = CGRectMake(0, 0, self.frame.size.width,  self.frame.size.height);
}

-(void)setupFrameBuffer {
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
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

- (void)display {
    [_glkView display];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    [EAGLContext setCurrentContext:_currentContext];
    
    GLuint attributeBuffer;
    glGenBuffers(1, &attributeBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attributeBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_DYNAMIC_DRAW);
    
    ///顶点,（向定位置填充数据）
    GLuint position = glGetAttribLocation(_program, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL);
    
    ///纹理坐标 （向纹理坐标填充数据）
    GLuint textCoor = glGetAttribLocation(_program, "textCoordinate");
    glEnableVertexAttribArray(textCoor);
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, (float *)NULL+3);
    
    GLuint texture =  [self setupTexture2:@"mouse"];
//    glUniform1i(glGetUniformLocation(_program, "colorMap"), 0);
    
    
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(_program);
    glDrawArrays(GL_TRIANGLES, 0, 6);
}



- (GLuint)setupTexture2:(NSString *)fileName {
    NSError *error;
    NSDictionary *optionDict = @{GLKTextureLoaderOriginBottomLeft:@(YES)};
    GLKTextureInfo *textureInfo  = [GLKTextureLoader textureWithCGImage:[UIImage imageNamed:fileName].CGImage options:optionDict error:&error];
    return textureInfo.name;
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
