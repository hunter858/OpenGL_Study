//
//  CCView.m
//  001--GLSL
//
//  Created by CC老师 on 2017/12/16.
//  Copyright © 2017年 CC老师. All rights reserved.
//
#import <OpenGLES/ES2/gl.h>
#import "OpenGLES/ES2/glext.h"
#import "YUVView.h"
#import <GLKit/GLKit.h>


GLfloat Vertex[]  = {
    1.0f, -1.0f, 0.0f,     1.0f, 0.0f, //右下角A
    -1.0f, 1.0f, 0.0f,     0.0f, 1.0f, //左上角B
    -1.0f, -1.0f, 0.0f,    0.0f, 0.0f, //左下角C
    
    1.0f, 1.0f, 0.0f,      1.0f, 1.0f, //右上角D
    -1.0f, 1.0f, 0.0f,     0.0f, 1.0f, //左上角B
    1.0f, -1.0f, 0.0f,     1.0f, 0.0f, //右下角A
};


const NSString *vertexShader = @"           \
attribute vec4 position;                    \
attribute vec2 texCoord;                    \
uniform float preferredRotation;            \
varying vec2 texCoordVarying;               \
void main()                                 \
{                                           \
    mat4 rotationMatrix = mat4(cos(preferredRotation), -sin(preferredRotation), 0.0, 0.0,   \
                                 sin(preferredRotation),  cos(preferredRotation), 0.0, 0.0, \
                                  0.0,                        0.0, 1.0, 0.0,                \
                                  0.0,                        0.0, 0.0, 1.0);               \
    gl_Position = position * rotationMatrix;                                                \
    texCoordVarying = texCoord;                                                             \
}                                                                                           \
";

const NSString *fragmentShader = @"             \
varying highp vec2 texCoordVarying;             \
precision mediump float;                        \
uniform sampler2D SamplerY;                     \
uniform sampler2D SamplerUV;                    \
uniform mat3 colorConversionMatrix;             \
void main()                                     \
{                                               \
    mediump vec3 yuv;                           \
    lowp vec3 rgb;                              \
    yuv.x = (texture2D(SamplerY, texCoordVarying).r - (16.0/255.0));        \
    yuv.yz = (texture2D(SamplerUV, texCoordVarying).rg - vec2(0.5, 0.5));   \
    rgb = colorConversionMatrix * yuv;                                      \
    gl_FragColor = vec4(rgb, 1);                                            \
}                                                                           \
";

// BT.601, which is the standard for SDTV.
static const GLfloat kColorConversion601[] = {
    1.164,  1.164, 1.164,
    0.0, -0.392, 2.017,
    1.596, -0.813,   0.0,
};

// BT.709, which is the standard for HDTV.
static const GLfloat kColorConversion709[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};

@interface YUVView()
{
    CGFloat _width;
    CGFloat _height;
    CAEAGLLayer *_myEagLayer;
    EAGLContext *_myContext;
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _myProgram;
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
    const GLfloat *_preferredConversion;
}

@end


@implementation YUVView

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
    if ([EAGLContext currentContext] != _myContext) {
        [EAGLContext setCurrentContext:_myContext];
    }
}


- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    
    if (!pixelBuffer) {
        return;
    }
    if (_pixelBuffer) {
        CFRelease(_pixelBuffer);
    }
    _pixelBuffer = CVPixelBufferRetain(pixelBuffer);
    [self ensureCurentContext];
    
    uint32_t width = (int)CVPixelBufferGetWidth(_pixelBuffer);
    uint32_t height = (int)CVPixelBufferGetHeight(_pixelBuffer);
    size_t planeCount = CVPixelBufferGetPlaneCount(_pixelBuffer);
    CFTypeRef colorAttachments = CVBufferGetAttachment(_pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
    /// 匹配原始图像pixeBuffer 的颜色空间，BT601 还是BT709
    if (CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) == kCFCompareEqualTo) {
        _preferredConversion = kColorConversion601;
    } else {
        _preferredConversion = kColorConversion709;
    }
    
    CVOpenGLESTextureCacheRef _videoTextureCache;
    CVReturn error = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _myContext, NULL, &_videoTextureCache);
    if (error != noErr) {
        NSLog(@"CVOpenGLESTextureCacheCreate error %d",error);
        return;
    }
    
    glActiveTexture(GL_TEXTURE0);
    /// 获取Y纹理
    error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                         _videoTextureCache,
                                                         _pixelBuffer,
                                                         NULL,
                                                         GL_TEXTURE_2D,
                                                         GL_RED_EXT,
                                                         width,
                                                         height,
                                                         GL_RED_EXT,
                                                         GL_UNSIGNED_BYTE,
                                                         0,
                                                         &_lumaTexture);
    if (error) {
        NSLog(@"error for reateTextureFromImage %d",error);
    }
    glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    /// 获取UV纹理

    if (planeCount == 2) {
        /// 获取UV纹理
        glActiveTexture(GL_TEXTURE1);
        error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                             _videoTextureCache,
                                                             _pixelBuffer,
                                                             NULL,
                                                             GL_TEXTURE_2D,
                                                             GL_RG_EXT,
                                                             width/2,
                                                             height/2,
                                                             GL_RG_EXT,
                                                             GL_UNSIGNED_BYTE,
                                                             1,
                                                             &_chromaTexture);
        if (error) {
            NSLog(@"error for reateTextureFromImage %d",error);
        }
        glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    

    glDisable(GL_DEPTH_TEST);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glViewport(0, 0, _width, _height);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glUseProgram(_myProgram);
    GLuint samplerY = glGetUniformLocation(_myProgram, "SamplerY");
    GLuint samplerUV = glGetUniformLocation(_myProgram, "SamplerUV");
    
    /// uniform
    GLint colorConversionMatrix = glGetUniformLocation(_myProgram, "colorConversionMatrix");
    GLint rotation = glGetUniformLocation(_myProgram, "preferredRotation");
    
    /// 旋转角度
    float radius = 180 * 3.14159f / 180.0f;
    
   
    /// 定义uniform 采样器对应纹理 0 也就是Y 纹理
    glUniform1i(samplerY, 0);
    
    glUniform1i(samplerUV, 1);
    /// 为当前程序对象指定Uniform变量的值
    glUniform1f(rotation, radius);
    ///  更新颜色空间矩阵的值 （bt601 /bt709）
    glUniformMatrix3fv(colorConversionMatrix, 1, GL_FALSE, _preferredConversion);
    /// 开始绘制
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    [_myContext presentRenderbuffer:GL_RENDERBUFFER];
    
    /// 清除纹理、释放内存
    [self cleanUpTextures];
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    if(_videoTextureCache) {
        CFRelease(_videoTextureCache);
    }
}

- (void)cleanUpTextures {
    if (_lumaTexture) {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    if (_chromaTexture) {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
}


- (void)loadShaders {
    //3.加载shader
    _myProgram = [self loadShaders:vertexShader  Withfrag:fragmentShader];
    
    //4.链接
    glLinkProgram(_myProgram);
    GLint linkStatus;
    //获取链接状态
    glGetProgramiv(_myProgram, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar message[512];
        glGetProgramInfoLog(_myProgram, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"Program Link Error:%@",messageString);
        return;
    }
    
    NSLog(@"Program Link Success!");
}

//6.开始绘制




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
    [_myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_myEagLayer];
    

    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);

    /// 加载顶点数据 和 纹理坐标
    GLuint attrBuffer;
    glGenBuffers(1, &attrBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex), Vertex, GL_DYNAMIC_DRAW);


    GLuint position = glGetAttribLocation(_myProgram, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, NULL);
    
    GLuint positionColor = glGetAttribLocation(_myProgram, "texCoord");
    glEnableVertexAttribArray(positionColor);
    glVertexAttribPointer(positionColor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5,(float *) NULL + 3);
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
    _myContext = context;
    
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
    
    
    //1.设置视口大小
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






