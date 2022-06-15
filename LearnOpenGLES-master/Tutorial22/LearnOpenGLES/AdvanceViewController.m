//
//  AdvanceViewController.m
//  LearnOpenGLES
//
//  Created by 林伟池 on 16/3/25.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "AdvanceViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"

#define const_length 512

@interface AdvanceViewController ()


@property (nonatomic , strong) EAGLContext* mContext;

@property (nonatomic , strong) GLKBaseEffect* mBaseEffect;
@property (nonatomic , strong) GLKBaseEffect* mExtraEffect;

@property (nonatomic , assign) int mCount;

@property (nonatomic , assign) GLint mDefaultFBO;
@property (nonatomic , assign) GLuint mExtraFBO;
@property (nonatomic , assign) GLuint mExtraDepthBuffer;
@property (nonatomic , assign) GLuint mExtraTexture;

@property (nonatomic , assign) long mBaseRotate;
@property (nonatomic , assign) long mExtraRotate;

@property (nonatomic , strong) IBOutlet UISwitch* mBaseSwitch;
@property (nonatomic , strong) IBOutlet UISwitch* mExtraSwitch;
@end


@implementation AdvanceViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //新建OpenGLES 上下文
    self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView* view = (GLKView *)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.mContext];
    
    GLfloat cubePositions[] = {
        
    };
    
    GLfloat cubeTexels[] = {
        
    };
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, cubePositions);
    
//    glEnableVertexAttribArray(GLKVertexAttribNormal);
//    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, cubeNormals);
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, cubeTexels);
    
    
    self.mBaseEffect = [[GLKBaseEffect alloc] init];
    self.mExtraEffect = [[GLKBaseEffect alloc] init];
    
//    self.mExtraEffect.light0.enabled = self.mBaseEffect.light0.enabled = GL_TRUE;
    self.mExtraEffect.light0.position = self.mBaseEffect.light0.position = GLKVector4Make(0.0f, 0.0f, 1.0f, 1.0f);
    self.mExtraEffect.light0.specularColor = self.mBaseEffect.light0.specularColor = GLKVector4Make(0.25f, 0.25f, 0.25f, 1.0f);
    self.mExtraEffect.light0.diffuseColor = self.mBaseEffect.light0.diffuseColor = GLKVector4Make(0.75f, 0.75f, 0.75f, 1.0f);
    self.mExtraEffect.lightingType = self.mBaseEffect.lightingType = GLKLightingTypePerPixel;
    
    glEnable(GL_DEPTH_TEST);
    
    [self preparePointOfViewWithAspectRatio:
     CGRectGetWidth(self.view.bounds) / CGRectGetHeight(self.view.bounds)];
    

    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"for_test" ofType:@"png"];
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:@(1), GLKTextureLoaderOriginBottomLeft, nil];

    GLKTextureInfo* textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    self.mExtraEffect.texture2d0.enabled = self.mBaseEffect.texture2d0.enabled = GL_TRUE;
    self.mExtraEffect.texture2d0.name = self.mBaseEffect.texture2d0.name = textureInfo.name;
    NSLog(@"panda texture %d", textureInfo.name);
    
    int width, height;
    width = self.view.bounds.size.width * self.view.contentScaleFactor;
    height = self.view.bounds.size.height * self.view.contentScaleFactor;
    [self extraInitWithWidth:width height:height]; //特别注意这里的大小
    
    self.mBaseRotate = self.mExtraRotate = 0;
}


//MVP矩阵
- (void)preparePointOfViewWithAspectRatio:(GLfloat)aspectRatio
{
    self.mExtraEffect.transform.projectionMatrix = self.mBaseEffect.transform.projectionMatrix =
    GLKMatrix4MakePerspective(
                              GLKMathDegreesToRadians(85.0f),
                              aspectRatio,
                              0.1f,
                              20.0f);
    
    self.mExtraEffect.transform.modelviewMatrix = self.mBaseEffect.transform.modelviewMatrix =
    GLKMatrix4MakeLookAt(
                         0.0, 0.0, 3.0,   // Eye position
                         0.0, 0.0, 0.0,   // Look-at position
                         0.0, 1.0, 0.0);  // Up direction
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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


- (void)update
{
    GLKMatrix4 modelViewMatrix;
    if (self.mBaseSwitch.on) {
        ++self.mBaseRotate;
        modelViewMatrix = GLKMatrix4Identity;
        modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0, 0, -3);
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(self.mBaseRotate), 1, 1, 1);
        self.mBaseEffect.transform.modelviewMatrix = modelViewMatrix;
    }
    
    if (self.mExtraSwitch.on) {
        self.mExtraRotate += 2;
        modelViewMatrix = GLKMatrix4Identity;
        modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0, 0, -3);
        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(self.mExtraRotate), 1, 1, 1);
        self.mExtraEffect.transform.modelviewMatrix = modelViewMatrix;
    }
}

- (void)renderFBO {
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, self.mExtraFBO);
    
    //如果视口和主缓存的不同，需要根据当前的大小调整，同时在下面的绘制时需要调整glviewport
//    glViewport(0, 0, const_length, const_length)
    glClearColor(0.3f, 0.3f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.mExtraEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, cubeVertices);

    glBindFramebuffer(GL_FRAMEBUFFER, self.mDefaultFBO);
    self.mBaseEffect.texture2d0.name = self.mExtraTexture;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self renderFBO];
    
    [((GLKView *) self.view) bindDrawable];
    

//    glViewport() 见上面
    glClearColor(0.3, 0.3, 0.3, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    

    [self.mBaseEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, cubeVertices);
}


- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation !=
            UIInterfaceOrientationPortraitUpsideDown);
}

@end

