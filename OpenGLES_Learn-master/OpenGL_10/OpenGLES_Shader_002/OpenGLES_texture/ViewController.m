//
//  ViewController.m
//  OpenGLES_texture
//
//  Created by xu jie on 16/8/22.
//  Copyright © 2016年 xujie. All rights reserved.
//

#import "ViewController.h"
#import "OSShaderManager.h"
static GLfloat vertex[8] = {
    1,1, //1
    -1,1,//0
    -1,-1, //2
    1,-1, //3
};

static GLfloat textureCoords[8] = {
    1,1,
    0,1,
    0,0,
    1,0
    
};


@interface ViewController (){
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _textureCoordBuffer;
    GLuint _textureBufferR;
    GLuint _textureBufferGB;
    GLuint _text2D;
    
  
}
@property(nonatomic,strong)OSShaderManager *shaderManager;
@property(nonatomic,strong)EAGLContext *eagContext;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    [self loadVertex];
    [self loadTexture];
}
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    glClearColor(1, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, 100, 100);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glViewport(150, 0, 100, 100);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
}

-(void)loadVertex{
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES( _vertexArray);
    // 加载顶点坐标
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertex), &vertex, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 8, NULL);
    
    //加载纹理坐标
    glGenBuffers(1, &_textureCoordBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _textureCoordBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(textureCoords), textureCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 8, NULL);
    glEnableVertexAttribArray(_vertexArray);
    
    
}


-(void)loadTexture{
    glUniform1i(_textureBufferR, 0); // 0 代表GL_TEXTURE0
    GLuint tex1;
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &tex1);
    glBindTexture(GL_TEXTURE_2D,  tex1);
    UIImage *image = [UIImage imageNamed:@"2.png"];
    GLubyte *imageData = [self getImageData:image];
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA , image.size.width, image.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData);
    free(imageData);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

}

/**
 *  获取图片数据的像素数据RGBA
 *
 *  @param image 图片
 *
 *  @return 像素数据
 */
- (void*)getImageData:(UIImage*)image{
    CGImageRef imageRef = [image CGImage];
    size_t imageWidth = CGImageGetWidth(imageRef);
    size_t imageHeight = CGImageGetHeight(imageRef);
    GLubyte *imageData = (GLubyte *)malloc(imageWidth*imageHeight*4);
    memset(imageData, 0,imageWidth *imageHeight*4);
    CGContextRef imageContextRef = CGBitmapContextCreate(imageData, imageWidth, imageHeight, 8, imageWidth*4, CGImageGetColorSpace(imageRef), kCGImageAlphaPremultipliedLast);
    CGContextTranslateCTM(imageContextRef, 0, imageHeight);
    CGContextScaleCTM(imageContextRef, 1.0, -1.0);
    CGContextDrawImage(imageContextRef, CGRectMake(0.0, 0.0, (CGFloat)imageWidth, (CGFloat)imageHeight), imageRef);
    CGContextRelease(imageContextRef);
    return  imageData;
}


-(void)setup{
    self.eagContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.eagContext];
    GLKView *view = (GLKView*)self.view;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.context = self.eagContext;
    
    self.shaderManager = [[OSShaderManager alloc]init];
    // 编译连个shader 文件
    GLuint vertexShader,fragmentShader;
    NSURL *vertexShaderPath = [[NSBundle mainBundle]URLForResource:@"Shader" withExtension:@"vsh"];
    NSURL *fragmentShaderPath = [[NSBundle mainBundle]URLForResource:@"Shader" withExtension:@"fsh"];
    if (![self.shaderManager compileShader:&vertexShader type:GL_VERTEX_SHADER URL:vertexShaderPath]||![self.shaderManager compileShader:&fragmentShader type:GL_FRAGMENT_SHADER URL:fragmentShaderPath]){
        return ;
    }
    // 注意获取绑定属性要在连接程序之前
    [self.shaderManager bindAttribLocation:GLKVertexAttribPosition andAttribName:"position"];
    [self.shaderManager bindAttribLocation:GLKVertexAttribTexCoord0 andAttribName:"texCoord0"];
    
   
    // 将编译好的两个对象和着色器程序进行连接
    if(![self.shaderManager linkProgram]){
        [self.shaderManager deleteShader:&vertexShader];
        [self.shaderManager deleteShader:&fragmentShader];
    }
    _textureBufferR = [self.shaderManager getUniformLocation:"sam2DR"];
    
    // 接触
    [self.shaderManager detachAndDeleteShader:&vertexShader];
    [self.shaderManager detachAndDeleteShader:&fragmentShader];
    [self.shaderManager useProgram];

    
}

@end
