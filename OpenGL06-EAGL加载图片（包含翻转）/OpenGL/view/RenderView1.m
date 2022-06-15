//
//  RenderView.m
//  OpenGL
//
//  Created by pengchao on 2022/1/7.
//
#import "RenderView1.h"
#import <GLKit/GLKit.h>


const NSString * fragmentShader1  =
@"precision highp float;            \
varying lowp vec2 varyTextCoord;    \
uniform sampler2D colorMap;         \
void main(){                        \
    gl_FragColor = texture2D(colorMap, varyTextCoord);\
}";


const NSString * vertexShader1 =
@"attribute vec4 position;                      \
attribute vec2 textCoordinate;                  \
uniform mat4 rotateMatrix;                      \
uniform mat4 scaleMatrix;                       \
varying lowp vec2 varyTextCoord;                \
void main(){                                    \
    varyTextCoord = textCoordinate;             \
    vec4 vPosition = position;                  \
    vPosition = vPosition * rotateMatrix * scaleMatrix;       \
    gl_Position = vPosition ;                   \
}";

GLfloat vertices1[]  = {
    0.5f, -0.5f, -1.0f,     1.0f, 0.0f, //右下角A
    -0.5f, 0.5f, -1.0f,     0.0f, 1.0f, //左上角B
    -0.5f, -0.5f, -1.0f,    0.0f, 0.0f, //左下角C
    
    0.5f, 0.5f, -1.0f,      1.0f, 1.0f, //右上角D
    -0.5f, 0.5f, -1.0f,     0.0f, 1.0f, //左上角B
    0.5f, -0.5f, -1.0f,     1.0f, 0.0f, //右下角A
};

@interface RenderView1 ()
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

@implementation RenderView1

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
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
    }
    return self;
}

- (void)layoutSubviews {
   
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
    GLuint vertexShader = [self loadShaderType:GL_VERTEX_SHADER fileName:vertexShader1];
    GLuint fragmentShader = [self loadShaderType:GL_FRAGMENT_SHADER fileName:fragmentShader1];
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

- (void)renderlayer {
    glViewport(0, 0, _frameWidth, _frameHeight);
    GLuint attributeBuffer;
    glGenBuffers(1, &attributeBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attributeBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices1), vertices1, GL_DYNAMIC_DRAW);
    
    ///顶点,（向定位置填充数据）
    GLuint position = glGetAttribLocation(_program, "position");
    glEnableVertexAttribArray(position);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL);
    
    ///纹理坐标 （向纹理坐标填充数据）
    GLuint textCoor = glGetAttribLocation(_program, "textCoordinate");
    glEnableVertexAttribArray(textCoor);
    glVertexAttribPointer(textCoor, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, (float *)NULL+3);
    glUseProgram(_program);
   

    GLuint texture = [self setupTexture:@"mouse"];
    ///通过glUniform1i的设置，我们保证每个uniform采样器对应着正确的纹理单元。
    ////对应纹理第0层；多个不同的纹理 对应的纹理采样器不一样
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [self rotateImage];
    /// 绘制

    
    glDrawArrays(GL_TRIANGLES, 0, 6);
  
    [_currentContext presentRenderbuffer:GL_RENDERBUFFER];
    
}


- (void)rotateImage {
   
    GLuint colorMap = glGetUniformLocation(_program, "colorMap");
    glUniform1i(colorMap, 0);
    
    ///1.获取旋转矩阵
    GLuint rotate = glGetUniformLocation(_program, "rotateMatrix");
    GLuint scale = glGetUniformLocation(_program, "scaleMatrix");

    
    // 1.获取旋转弧度
    float radius = 180 * 3.14159f / 180.0f;
    float sin = sin(radius);
    float cos = cos(radius);
    GLfloat rotateMatrix[16] = {
        cos,-sin,0 ,0,
        sin,cos,0 ,0,
        0,0,1 ,0,
        0,0,0 ,1,
    };

    GLfloat scaleMartix[16] = {
        -1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    };
    
    glUniformMatrix4fv(rotate, 1, GL_FALSE, rotateMatrix);
    glUniformMatrix4fv(scale, 1, GL_FALSE, scaleMartix);
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

    // 4、创建上下文
    /*
    参数1：data,指向要渲染的绘制图像的内存地址
    参数2：width,bitmap的宽度，单位为像素
    参数3：height,bitmap的高度，单位为像素
    参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
    参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
    参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
    */
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    NSLog(@"kCGImageAlphaPremultipliedLast %d", kCGImageAlphaPremultipliedLast);


//    5、在CGContextRef上 --- 将图片绘制出来
    /*
    CGContextDrawImage 使用的是Core Graphics框架，坐标系与UIKit 不一样。UIKit框架的原点在屏幕的左上角，Core Graphics框架的原点在屏幕的左下角。
    CGContextDrawImage
    参数1：绘图上下文
    参数2：rect坐标
    参数3：绘制的图片
    */

    CGRect rect = CGRectMake(0, 0, width, height);

    //6、使用默认方式绘制
    CGContextDrawImage(spriteContext, rect, spriteImage);

    //7、画图完毕就释放上下文
    CGContextRelease(spriteContext);

    //8、绑定纹理到默认的纹理ID
    glBindTexture(GL_TEXTURE_2D, 1);

    //9、设置纹理属性
    /*
    参数1：纹理维度
    参数2：线性过滤、为s,t坐标设置模式
    参数3：wrapMode,环绕模式
    */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    float fw = width, fh = height;
    //10、载入纹理2D数据
    /*
    参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
    参数2：加载的层次，一般设置为0
    参数3：纹理的颜色值GL_RGBA
    参数4：宽
    参数5：高
    参数6：border，边界宽度
    参数7：format
    参数8：type
    参数9：纹理数据
    */
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, fw, fh, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);

    //11、释放spriteData
    free(spriteData);
    return 0;
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
