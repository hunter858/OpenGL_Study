//
//  RenderView.m
//  OpenGL
//
//  Created by pengchao on 2022/1/7.
//
#import "RenderView2.h"
#import <GLKit/GLKit.h>


const NSString * fragmentShader2  =
@"precision highp float;            \
varying lowp vec2 varyTextCoord;    \
uniform sampler2D colorMap;         \
void main(){                        \
    gl_FragColor = texture2D(colorMap, varyTextCoord);\
}";


const NSString * vertexShader2 =
@"attribute vec4 position;                      \
attribute vec2 textCoordinate;                  \
uniform mat4 rotateMatrix;                      \
varying lowp vec2 varyTextCoord;                \
void main(){                                    \
    varyTextCoord = textCoordinate;             \
    gl_Position = position ;                    \
}";

GLfloat vertices2[]  = {
    0.5f, -0.5f, -1.0f,     1.0f, 0.0f, //右下角A
    -0.5f, 0.5f, -1.0f,     0.0f, 1.0f, //左上角B
    -0.5f, -0.5f, -1.0f,    0.0f, 0.0f, //左下角C
    
    0.5f, 0.5f, -1.0f,      1.0f, 1.0f, //右上角D
    -0.5f, 0.5f, -1.0f,     0.0f, 1.0f, //左上角B
    0.5f, -0.5f, -1.0f,     1.0f, 0.0f, //右下角A
};

@interface RenderView2 ()
{
    CAEAGLLayer *_eaglLayer;
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _program;
    GLuint _vertexColor;
    EAGLContext *_currentContext;
    
    GLint _frameWidth;
    GLint _frameHeight;
}
@end

@implementation RenderView2

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (void)layoutSubviews {
    _currentContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _eaglLayer = (CAEAGLLayer *) self.layer;
    _eaglLayer.frame = self.frame;
    _eaglLayer.opaque = YES;
    _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:YES],kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
    [EAGLContext setCurrentContext:_currentContext];
    
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupBindFrameBuffer];
    [self setupProgram];
    [self renderlayer];
}

+(Class)layerClass{
    return [CAEAGLLayer class];
}


- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [_currentContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}


-(void)setupFrameBuffer {
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
}

- (void)setupBindFrameBuffer {
    /// 获取渲染的width、height
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_frameWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_frameHeight);
}

- (void)setupProgram {
    GLuint vertexShader = [self loadShaderType:GL_VERTEX_SHADER fileName:vertexShader2];
    GLuint fragmentShader = [self loadShaderType:GL_FRAGMENT_SHADER fileName:fragmentShader2 ];
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

- (void)renderlayer{
    glViewport(0, 0, _frameWidth, _frameHeight);
    GLuint attributeBuffer;
    glGenBuffers(1, &attributeBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attributeBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices2), vertices2, GL_DYNAMIC_DRAW);
    
    ///顶点,（向定位置填充数据）
    GLuint position = glGetAttribLocation(_program, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL);
    
    ///纹理坐标 （向纹理坐标填充数据）
    GLuint textCoor = glGetAttribLocation(_program, "textCoordinate");
    glEnableVertexAttribArray(textCoor);
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, (float *)NULL+3);
    
    GLuint colorMap = glGetUniformLocation(_program, "colorMap");
   
    
    GLuint texture =  [self setupTexture2:@"mouse"];
    [_currentContext presentRenderbuffer:_renderBuffer];
    
    /// 绘制
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(_program);
    glDrawArrays(GL_TRIANGLES, 0, 6);
  
    [_currentContext presentRenderbuffer:GL_RENDERBUFFER];
    
}


- (GLuint)setupTexture: (NSString *)fileName {
    //1、将UIImage转换为CGImageRef & 判断图片是否获取成功
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;

    if (!spriteImage) {
        NSLog(@"Failed to lead image %@", fileName);
        exit(1);
    }

    //2、读取图片的大小、宽和高
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    //3、获取图片字节数 宽*高*4（RGBA）
    GLubyte *spriteData = (GLubyte *)calloc(width*height*4, sizeof(GLubyte));
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    NSLog(@"kCGImageAlphaPremultipliedLast %d", kCGImageAlphaPremultipliedLast);
    CGRect rect = CGRectMake(0, 0, width, height);
    //6、使用默认方式绘制
    CGContextDrawImage(spriteContext, rect, spriteImage);
    //7、画图完毕就释放上下文
    CGContextRelease(spriteContext);

    //8、绑定纹理到默认的纹理ID
    glBindTexture(GL_TEXTURE_2D, 1);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    float fw = width, fh = height;
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);

    //11、释放spriteData
    free(spriteData);
    return 0;
}

- (GLuint)setupTexture2:(NSString *)fileName {
    NSDictionary *option = @{GLKTextureLoaderOriginBottomLeft: @(YES)};
    NSError *error;
    GLKTextureInfo *textureInfo  = [GLKTextureLoader textureWithCGImage:[UIImage imageNamed:fileName].CGImage options:option error:&error];
    return textureInfo.name;
}




- (GLuint)loadShaderType:(GLenum)type fileName:(NSString *)shaderName {
    
    NSString *shaderString = shaderName;
    if (!shaderString) {
        NSLog(@"Error loading shader:");
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

