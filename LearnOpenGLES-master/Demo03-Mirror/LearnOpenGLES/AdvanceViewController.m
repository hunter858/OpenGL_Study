//
//  AdvanceViewController.m
//  LearnOpenGLES
//
//  Created by 林伟池 on 16/3/25.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "AdvanceViewController.h"

@interface AdvanceViewController ()

@property (nonatomic , strong) EAGLContext* mContext;
@property (nonatomic , strong) GLKBaseEffect* mEffect;
@property (nonatomic , strong) GLKBaseEffect* mMirrorEffect;

@property (nonatomic , assign) float mDegreeX;
@property (nonatomic , assign) float mDegreeY;
@property (nonatomic , assign) float mDegreeZ;

@property (nonatomic , assign) BOOL mBoolX;
@property (nonatomic , assign) BOOL mBoolY;
@property (nonatomic , assign) BOOL mBoolZ;

@property (nonatomic , assign) GLint mDefaultFBO;
@property (nonatomic , assign) GLuint mExtraFBO;
@property (nonatomic , assign) GLuint mExtraDepthBuffer;
@property (nonatomic , assign) GLuint mExtraTexture;

@property (nonatomic , assign) int mCount;
@property (nonatomic , assign) GLuint mAttr;
@property (nonatomic , assign) GLuint mIndicesAttr;
@property (nonatomic , assign) GLuint mMirrorAttr;
@end

@implementation AdvanceViewController
{
    dispatch_source_t timer;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    //新建OpenGLES 上下文
    self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView* view = (GLKView *)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.mContext];
    glEnable(GL_DEPTH_TEST);
    
    //新的图形
    [self renderNew];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)renderNew {
    
    //顶点数据，前三个是顶点坐标， 中间三个是顶点颜色，    最后两个是纹理坐标
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       0.0f, 1.0f,//左上
        0.5f, 0.5f, 0.0f,       0.0f, 0.5f, 0.0f,       1.0f, 1.0f,//右上
        -0.5f, -0.5f, 0.0f,     0.5f, 0.0f, 1.0f,       0.0f, 0.0f,//左下
        0.5f, -0.5f, 0.0f,      0.0f, 0.0f, 0.5f,       1.0f, 0.0f,//右下
        0.0f, 0.0f, 1.0f,       1.0f, 1.0f, 1.0f,       0.5f, 0.5f,//顶点
    };
    //顶点索引
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    self.mCount = sizeof(indices) / sizeof(GLuint);
    
    GLfloat mirrorAttr[] =
    {
        -1.0f, -1.0f, 1.0f,             1.0f, 1.0f,
        1.0f, -1.0f, 1.0f,              0.0f, 1.0f,
        -1.0f, -1.0f, -1.0f,             1.0f, 0.0f,
        1.0f, -1.0f, -1.0f,              0.0f, 0.0f,
    };
    
//    self.preferredFramesPerSecond
    
    glGenBuffers(1, &_mMirrorAttr);
    glBindBuffer(GL_ARRAY_BUFFER, _mMirrorAttr);
    glBufferData(GL_ARRAY_BUFFER, sizeof(mirrorAttr), mirrorAttr, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_mAttr);
    glBindBuffer(GL_ARRAY_BUFFER, _mAttr);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_mIndicesAttr);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _mIndicesAttr);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL);
    //顶点颜色
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 3);
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 6);
    
    
    //纹理
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"for_test" ofType:@"png"];
    
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo* textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    //着色器
    self.mEffect = [[GLKBaseEffect alloc] init];
    self.mEffect.texture2d0.enabled = GL_TRUE;
    self.mEffect.texture2d0.name = textureInfo.name;
    
    self.mMirrorEffect = [[GLKBaseEffect alloc] init];
    self.mMirrorEffect.texture2d0.enabled = GL_TRUE;
    self.mMirrorEffect.texture2d0.name = textureInfo.name;
    
    
    
    //初始的投影
    CGSize size = self.view.bounds.size;
    float aspect = fabs(size.width / size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1f, 10.f);
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.0f, 1.0f, 1.0f);
    self.mEffect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -4.0f);
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
    
    self.mMirrorEffect.transform.projectionMatrix = projectionMatrix;
    modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, 0.0f);
    self.mMirrorEffect.transform.modelviewMatrix = GLKMatrix4MakeLookAt(0.0, 3.0, 2.0,
                                                                        0.0, 0.0, -1.0,
                                                                        0, 0, 1);
//    self.mMirrorEffect.transform.modelviewMatrix = GLKMatrix4Translate(self.mMirrorEffect.transform.modelviewMatrix, 0, 0.5, 0);
    
    //定时器
    double delayInSeconds = 0.1;
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC, 0.0);
    dispatch_source_set_event_handler(timer, ^{
        self.mDegreeX += 0.1  * self.mBoolX;
        self.mDegreeY += 0.1 * self.mBoolY;
        self.mDegreeZ += 0.1 * self.mBoolZ;
        
    });
    dispatch_resume(timer);
    
    
    int width, height;
    width = self.view.bounds.size.width * self.view.contentScaleFactor;
    height = self.view.bounds.size.height * self.view.contentScaleFactor;
    [self extraInitWithWidth:width height:height]; //特别注意这里的大小
}

-(IBAction)onX:(id)sender {
    self.mBoolX = !self.mBoolX;
}

-(IBAction)onY:(id)sender {
    self.mBoolY = !self.mBoolY;
}

-(IBAction)onZ:(id)sender {
    self.mBoolZ = !self.mBoolZ;
}



- (void)extraInitWithWidth:(GLint)width height:(GLint)height {
    
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &_mDefaultFBO);
    glGenTextures(1, &_mExtraTexture);
    NSLog(@"render texture %d", self.mExtraTexture);
    glGenFramebuffers(1, &_mExtraFBO);
    glGenRenderbuffers(1, &_mExtraDepthBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, self.mExtraFBO);
    glBindTexture(GL_TEXTURE_2D, self.mExtraTexture);
    
    
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_RGBA,
                 width,
                 height,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    
    
    glFramebufferTexture2D(GL_FRAMEBUFFER,
                           GL_COLOR_ATTACHMENT0,
                           GL_TEXTURE_2D, self.mExtraTexture, 0);
    
    
    glBindRenderbuffer(GL_RENDERBUFFER, self.mExtraDepthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16,
                          width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, self.mExtraDepthBuffer);
    
    GLenum status;
    status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    switch(status) {
        case GL_FRAMEBUFFER_COMPLETE:
            NSLog(@"fbo complete width %d height %d", width, height);
            break;
            
        case GL_FRAMEBUFFER_UNSUPPORTED:
            NSLog(@"fbo unsupported");
            break;
            
        default:
            NSLog(@"Framebuffer Error");
            break;
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.mDefaultFBO);
    glBindTexture(GL_TEXTURE_2D, 0);
}


/**
 *  场景数据变化
 */
- (void)update {
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0f, 0.0f, -4.0f);
    
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, self.mDegreeX);
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, self.mDegreeY);
    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, self.mDegreeZ);
    
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
}

- (void)renderFBO {
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, self.mExtraFBO);
    
    //如果视口和主缓存的不同，需要根据当前的大小调整，同时在下面的绘制时需要调整glviewport
    //    glViewport(0, 0, const_length, const_length)
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.mEffect prepareToDraw];
    glDrawElements(GL_TRIANGLES, self.mCount, GL_UNSIGNED_INT, 0);
    
    glBindFramebuffer(GL_FRAMEBUFFER, self.mDefaultFBO);
    self.mMirrorEffect.texture2d0.name = self.mExtraTexture;
}


/**
 *  渲染场景代码
 */
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self renderFBO];
    
    [((GLKView *) self.view) bindDrawable];
    glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // mirror
    glBindBuffer(GL_ARRAY_BUFFER, self.mMirrorAttr);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL);
    
    glBindBuffer(GL_ARRAY_BUFFER, self.mMirrorAttr);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (GLfloat *)NULL + 3);
    glDisableVertexAttribArray(GLKVertexAttribColor);
    [self.mMirrorEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    
    // base
    glBindBuffer(GL_ARRAY_BUFFER, self.mAttr);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 8, (GLfloat *)NULL + 3);
    [self.mEffect prepareToDraw];
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _mIndicesAttr);
    glDrawElements(GL_TRIANGLES, self.mCount, GL_UNSIGNED_INT, 0);
    
}


@end
