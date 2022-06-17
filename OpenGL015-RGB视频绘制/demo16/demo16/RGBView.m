//
//  CCView.m
//  001--GLSL
//
//  Created by CC老师 on 2017/12/16.
//  Copyright © 2017年 CC老师. All rights reserved.
//
#import "OpenGLES/ES2/glext.h"
#import "RGBView.h"


GLfloat Vertex[]  = {
    -1.0f, 1.0f,     0.0f, 1.0f, //左上角A
    1.0f, 1.0f,      1.0f, 1.0f, //右上角B
    1.0f, -1.0f,     1.0f, 0.0f, //右下角C
    -1.0f, -1.0f,    0.0f, 0.0f, //左下角D
};

GLuint elementIndex[] =
{
    0, 3, 2,
    0, 2, 1,
};


const NSString *vertexShader = @"                                                           \
attribute vec4 position;                                                                    \
attribute vec4 texCoord;                                                                    \
uniform float preferredRotation;                                                            \
varying vec2 texCoordVarying;                                                               \
void main()                                                                                 \
{                                                                                           \
    mat4 rotationMatrix = mat4(cos(preferredRotation), -sin(preferredRotation), 0.0, 0.0,   \
                               sin(preferredRotation),  cos(preferredRotation), 0.0, 0.0,   \
                               0.0,                        0.0, 1.0, 0.0,                   \
                               0.0,                        0.0, 0.0, 1.0);                  \
    gl_Position = position * rotationMatrix;                                                \
    texCoordVarying = texCoord.xy;                                                          \
}                                                                                           \
";

const NSString *fragmentShader = @"                                        \
varying highp vec2 texCoordVarying;                                        \
uniform sampler2D texture;                                                 \
void main()                                                                \
{                                                                          \
    gl_FragColor = texture2D(texture, texCoordVarying);                    \
}                                                                          \
";



@interface RGBView()
{
    CGFloat _width;
    CGFloat _height;
    CAEAGLLayer *_myEagLayer;
    EAGLContext *_context;
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _program;
    CVOpenGLESTextureRef _rgbTexture;
}

@end


@implementation RGBView

@synthesize pixelBuffer = _pixelBuffer;

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        //1.设置图层
        [self setupLayer];
        
        //2.设置图形上下文
        [self setupContext];
        
        //3. 加载shader
        [self loadShaders];
        
        //4.设置FrameBuffer
        [self setupFrameBuffer];
    }
    return self;
}

+(Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)ensureCurentContext {
    if ([EAGLContext currentContext] != _context) {
        [EAGLContext setCurrentContext:_context];
    }
}


- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    
    if (!pixelBuffer) {
        return;
    }
    if (_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
    }
    _pixelBuffer = CVPixelBufferRetain(pixelBuffer);
    [self ensureCurentContext];
    
    uint32_t width = (int)CVPixelBufferGetWidth(_pixelBuffer);
    uint32_t height = (int)CVPixelBufferGetHeight(_pixelBuffer);

    
    CVOpenGLESTextureCacheRef _videoTextureCache;
    CVReturn error = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
    if (error != noErr) {
        NSLog(@"CVOpenGLESTextureCacheCreate error %d",error);
        return;
    }
    
    glActiveTexture(GL_TEXTURE0);
    /// 获取RGB纹理
    error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                         _videoTextureCache,
                                                         _pixelBuffer,
                                                         NULL,
                                                         GL_TEXTURE_2D,
                                                         GL_RGBA,
                                                         width,
                                                         height,
                                                         GL_BGRA,
                                                         GL_UNSIGNED_BYTE,
                                                         0,
                                                         &_rgbTexture);
    if (error) {
        NSLog(@"error for reateTextureFromImage %d",error);
    }
    glBindTexture(CVOpenGLESTextureGetTarget(_rgbTexture), CVOpenGLESTextureGetName(_rgbTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glDisable(GL_DEPTH_TEST);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glViewport(0, 0, _width, _height);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glUseProgram(_program);
    GLuint textureUniform = glGetUniformLocation(_program, "texture");
    
    
    /// uniform
    GLint rotation = glGetUniformLocation(_program, "preferredRotation");
    
    /// 旋转角度
    float radius = 180 * 3.14159f / 180.0f;
    
    /// 定义uniform 采样器对应纹理 0 也就是Y 纹理
    glUniform1i(textureUniform, 0);

    /// 为当前程序对象指定Uniform变量的值
    glUniform1f(rotation, radius);
    /// 开始绘制
    glDrawElements(GL_TRIANGLES, sizeof(elementIndex)/sizeof(elementIndex[0]), GL_UNSIGNED_INT, elementIndex);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
    /// 清除纹理、释放内存
    [self cleanUpTextures];
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    if(_videoTextureCache) {
        CFRelease(_videoTextureCache);
    }
}


- (void)cleanUpTextures {
    if (_rgbTexture) {
        CFRelease(_rgbTexture);
        _rgbTexture = NULL;
    }
}


- (void)loadShaders {
    //3.加载shader
    _program = [self loadShaders:vertexShader  Withfrag:fragmentShader];
    
    //4.链接
    glLinkProgram(_program);
    GLint linkStatus;
    //获取链接状态
    glGetProgramiv(_program, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar message[512];
        glGetProgramInfoLog(_program, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"Program Link Error:%@",messageString);
        return;
    }
    
    NSLog(@"Program Link Success!");
}

//5.设置FrameBuffer
- (void)setupFrameBuffer
{
    //1.清除之前的frameBuffer 和renderBuffer
    glDeleteBuffers(1, &_frameBuffer);
    _frameBuffer = 0;
    
    glDeleteBuffers(1, &_renderBuffer);
    _renderBuffer = 0;
    
    //1.定义一个缓存区ID
    GLuint buffer;
    //2.申请一个缓存区标志
    glGenFramebuffers(1, &buffer);
    //3.赋值属性
    _frameBuffer = buffer;
    
    ///4. renderBuffer
    GLuint renderBuffer;
    glGenRenderbuffers(1, &renderBuffer);
    _renderBuffer = renderBuffer;
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_myEagLayer];
    

    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);

    /// 加载顶点数据 和 纹理坐标
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex), Vertex, GL_DYNAMIC_DRAW);
    

    GLuint position = glGetAttribLocation(_program, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 4, NULL);
    
    GLuint positionColor = glGetAttribLocation(_program, "texCoord");
    glEnableVertexAttribArray(positionColor);
    glVertexAttribPointer(positionColor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 4,(float *) NULL + 2);
}


//2.设置上下文
-(void)setupContext
{
    //1.指定OpenGL ES 渲染API版本，我们使用2.0
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    //2.创建图形上下文
    EAGLContext *context = [[EAGLContext alloc]initWithAPI:api];
    //3.判断是否创建成功
    if (!context) {
        NSLog(@"Create context failed!");
        return;
    }
    //4.设置图形上下文
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"setCurrentContext failed!");
        return;
    }
    //5.将局部context，变成全局的
    _context = context;
    
}

//1.设置图层
- (void)setupLayer
{
    //1.创建特殊图层
    /*
     重写layerClass，将CCView返回的图层从CALayer替换成CAEAGLLayer
     */
    _myEagLayer = (CAEAGLLayer *)self.layer;
    
    //2.设置scale
    [self setContentScaleFactor:[[UIScreen mainScreen]scale]];


    //3.设置描述属性，这里设置不维持渲染内容以及颜色格式为RGBA8
    _myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false,kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat,nil];
    
    //4.设置视口大小
    CGFloat scale = [[UIScreen mainScreen]scale];
    _width = self.frame.size.width *scale;
    _height = self.frame.size.height *scale;
}


#pragma mark --shader
//加载shader
-(GLuint)loadShaders:(NSString *)vert Withfrag:(NSString *)frag
{
    //1.定义2个零时着色器对象
    GLuint verShader, fragShader;
    //创建program
    GLint program = glCreateProgram();
    
    //2.编译顶点着色程序、片元着色器程序
    //参数1：编译完存储的底层地址
    //参数2：编译的类型，GL_VERTEX_SHADER（顶点）、GL_FRAGMENT_SHADER(片元)
    //参数3：文件路径
    [self compileShader:&verShader type:GL_VERTEX_SHADER content:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER content:frag];
    
    //3.创建最终的程序
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //4.释放不需要的shader
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

//编译shader
- (void)compileShader:(GLuint *)shader type:(GLenum)type content:(NSString *)content {
    
    //1.读取文件路径字符串
    const GLchar* source = (GLchar *)[content UTF8String];
    
    //2.创建一个shader（根据type类型）
    *shader = glCreateShader(type);
    
    //3.将着色器源码附加到着色器对象上。
    //参数1：shader,要编译的着色器对象 *shader
    //参数2：numOfStrings,传递的源码字符串数量 1个
    //参数3：strings,着色器程序的源码（真正的着色器程序源码）
    //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &source,NULL);
    
    //4.把着色器源代码编译成目标代码
    glCompileShader(*shader);
}

@end






