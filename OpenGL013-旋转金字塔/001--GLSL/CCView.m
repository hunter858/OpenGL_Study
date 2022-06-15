//
//  CCView.m
//  001--GLSL
//
//  Created by CC老师 on 2017/12/16.
//  Copyright © 2017年 CC老师. All rights reserved.
//
/*
 不采样GLKBaseEffect，使用编译链接自定义的着色器（shader）。用简单的glsl语言来实现顶点、片元着色器，并图形进行简单的变换。
 思路：
   1.创建图层
   2.创建上下文
   3.清空缓存区
   4.设置RenderBuffer
   5.设置FrameBuffer
   6.开始绘制
 
 */
#import <OpenGLES/ES2/gl.h>
#import "CCView.h"
#import <GLKit/GLKit.h>
#import "GLESUtils.h"
#import "GLESMath.h"

@interface CCView()
{
    CGFloat _width;
    CGFloat _height;
}
//在iOS和tvOS上绘制OpenGL ES内容的图层，继承与CALayer
@property(nonatomic,strong)CAEAGLLayer *myEagLayer;

@property(nonatomic,strong)EAGLContext *myContext;

@property(nonatomic,assign)GLuint frameBuffer;

@property(nonatomic,assign)GLuint renderBuffer;

@property(nonatomic,assign)GLuint myProgram;


@end


 GLfloat Vertex[] =
{
    -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, //左上0 （B）
    0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, //右上1 （A）
    -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, //左下2 （C）
    
    0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, //右下3  (D)
    0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f, //顶点4  (E)
};

GLuint elementIndex[] =
{
    0, 3, 2,
    0, 1, 3,
    0, 2, 4,
    0, 4, 1,
    2, 3, 4,
    1, 4, 3,
};



const NSString *vertexShader = @"           \
attribute vec4 position;                    \
attribute vec4 positionColor;               \
uniform mat4 projectionMatrix;              \
uniform mat4 modelViewMatrix;               \
varying lowp vec4 varyColor;                \
void main()                                 \
{                                           \
    varyColor = positionColor;              \
    vec4 vPos;                              \
    vPos = projectionMatrix * modelViewMatrix * position;\
    gl_Position = vPos;                     \
}\
";

const NSString *fragmentShader = @"         \
varying lowp vec4 varyColor;                \
void main()                                 \
{                                           \
    gl_FragColor = varyColor;               \
}                                           \
";


@implementation CCView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        //1.设置图层
        [self setupLayer];
        
        //2.设置图形上下文
        [self setupContext];
        
        //3.清空缓存区
        [self deleteRenderAndFrameBuffer];
        
        //4.设置FrameBuffer
        [self setupFrameBuffer];
        
        //6.开始绘制
        [self renderLayer];
    }
    return self;
}


- (void)setRoate_x:(CGFloat)roate_x {
    _roate_x = roate_x;
    [self renderLayer];
}

- (void)setRoate_y:(CGFloat)roate_y {
    _roate_y = roate_y;
    [self renderLayer];
}

-(void)setRoate_z:(CGFloat)roate_z {
    _roate_z = roate_z;
    [self renderLayer];
}

#pragma mark renderLayer

//6.开始绘制
- (void)renderLayer
{
    //设置清屏颜色
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    //清除屏幕
    glClear(GL_COLOR_BUFFER_BIT);
    
    //1.设置视口大小
    CGFloat scale = [[UIScreen mainScreen]scale];
    _width = self.frame.size.width *scale;
    _height = self.frame.size.height *scale;
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, _width, _height);
 
    
    //3.加载shader
    self.myProgram = [self loadShaders:NULL  Withfrag:NULL];
    
    //4.链接
    glLinkProgram(self.myProgram);
    GLint linkStatus;
    //获取链接状态
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLchar message[512];
        glGetProgramInfoLog(self.myProgram, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"Program Link Error:%@",messageString);
        return;
    }
    
    NSLog(@"Program Link Success!");
    //5.使用program
    glUseProgram(self.myProgram);
    
    //6.设置顶点、纹理坐标
    //前3个是顶点坐标，后2个是纹理坐标
   
    
    
    //7.-----处理顶点数据--------
    //(1)顶点缓存区
    GLuint attrBuffer;
    //(2)申请一个缓存区标识符
    glGenBuffers(1, &attrBuffer);
    //(3)将attrBuffer绑定到GL_ARRAY_BUFFER标识符上
    glBindBuffer(GL_ARRAY_BUFFER, attrBuffer);
    //(4)把顶点数据从CPU内存复制到GPU上
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertex), Vertex, GL_DYNAMIC_DRAW);

    //8.将顶点数据通过myPrograme中的传递到顶点着色程序的position
    //1.glGetAttribLocation,用来获取vertex attribute的入口的.
    //2.告诉OpenGL ES,通过glEnableVertexAttribArray，
    //3.最后数据是通过glVertexAttribPointer传递过去的。
    
    //(1)注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    
    //(2).设置合适的格式从buffer里面读取数据
    glEnableVertexAttribArray(position);
    
    //(3).设置读取方式
    //参数1：index,顶点数据的索引
    //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
    //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
    //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
    //参数5：stride,连续顶点属性之间的偏移量，默认为0；
    //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6, NULL);
    
    
    ///颜色
    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
    glEnableVertexAttribArray(positionColor);
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 6,(float *) NULL +3);
    
    
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");

    /// 加载单位矩阵
    KSMatrix4 _projectionMatrix ;
    ksMatrixLoadIdentity(&_projectionMatrix);
    float aspect = _width / _height; //长宽比
    ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 40.0f); //透视变换，视角30°
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE,(GLfloat*)&_projectionMatrix.m[0][0]);
    
    
   
    /// 单元矩阵 沿着y轴移动
    KSMatrix4 _modelViewMatrix ;
    ksMatrixLoadIdentity(&_modelViewMatrix);
    ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
    

    KSMatrix4 _rotationMatrix;
    /// 初始化为单元矩阵
    ksMatrixLoadIdentity(&_rotationMatrix);
    ksRotate(&_rotationMatrix, _roate_x*360, 1.0, 0.0, 0.0); //绕X轴
    ksRotate(&_rotationMatrix, _roate_y*360, 0.0, 1.0, 0.0); //绕Y轴
    ksRotate(&_rotationMatrix, _roate_z*360, 0.0, 0.0, 1.0); //绕Z轴
    /// 矩阵相乘
    ksMatrixMultiply(&_modelViewMatrix ,&_rotationMatrix, &_modelViewMatrix);
    

    /// 将_modelViewMatrix 的值传入shader
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat*)&_modelViewMatrix.m[0][0]);
    /// 开启剔除操作效果消除不必要的渲染计算。
    glEnable(GL_CULL_FACE);
    /// 索引绘制
    glDrawElements(GL_TRIANGLES, sizeof(elementIndex)/sizeof(elementIndex[0]), GL_UNSIGNED_INT, elementIndex);
    
    //13.从渲染缓存区显示到屏幕上
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}



//5.设置FrameBuffer
- (void)setupFrameBuffer
{
    //1.定义一个缓存区ID
    GLuint buffer;
    //2.申请一个缓存区标志
    glGenFramebuffers(1, &buffer);
    //3.赋值属性
    self.frameBuffer = buffer;
    
    ///4. renderBuffer
    GLuint renderBuffer;
    glGenRenderbuffers(1, &renderBuffer);
    self.renderBuffer = renderBuffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.renderBuffer);
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
    
    
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.renderBuffer);
    
    
}


//3.清空缓存区
- (void)deleteRenderAndFrameBuffer
{
    /*
     buffer分为frame buffer 和 render buffer2个大类。
     其中frame buffer 相当于render buffer的管理者。
     frame buffer object即称FBO。
     render buffer则又可分为3类。colorBuffer、depthBuffer、stencilBuffer。
     */
    
    glDeleteBuffers(1, &_frameBuffer);
    self.frameBuffer = 0;
    
    
    glDeleteBuffers(1, &_renderBuffer);
    self.renderBuffer = 0;
    
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
    self.myContext = context;
    
}

//1.设置图层
- (void)setupLayer
{
    //1.创建特殊图层
    /*
     重写layerClass，将CCView返回的图层从CALayer替换成CAEAGLLayer
     */
    self.myEagLayer = (CAEAGLLayer *)self.layer;
    
    //2.设置scale
    [self setContentScaleFactor:[[UIScreen mainScreen]scale]];


    //3.设置描述属性，这里设置不维持渲染内容以及颜色格式为RGBA8
    /*
     kEAGLDrawablePropertyRetainedBacking  表示绘图表面显示后，是否保留其内容。
     kEAGLDrawablePropertyColorFormat
         可绘制表面的内部颜色缓存区格式，这个key对应的值是一个NSString指定特定颜色缓存区对象。默认是kEAGLColorFormatRGBA8；
     
         kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位
         kEAGLColorFormatRGB565：16位RGB的颜色，
         kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素。sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。


     */
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@false,kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat,nil];
    
}





+(Class)layerClass
{
    return [CAEAGLLayer class];
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
    [self compileShader:&verShader type:GL_VERTEX_SHADER content:vertexShader];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER content:fragmentShader];
    
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



- (UIImage *)imageWithPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];

    CIContext *temporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef videoImage = [temporaryContext
        createCGImage:ciImage
             fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];

    UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
    CGImageRelease(videoImage);

    return uiImage;
}

@end






