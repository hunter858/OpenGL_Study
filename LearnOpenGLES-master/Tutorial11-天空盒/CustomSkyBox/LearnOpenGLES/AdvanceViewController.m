//
//  AdvanceViewController.m
//  LearnOpenGLES
//
//  Created by 林伟池 on 16/3/25.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "AdvanceViewController.h"
#import "starship.h"
#import "AGLKSkyboxEffect.h"


@interface AdvanceViewController ()
{
}

@property (nonatomic , strong) EAGLContext* mContext;

@property (strong, nonatomic) GLKBaseEffect *baseEffect;
@property (strong, nonatomic) AGLKSkyboxEffect *skyboxEffect;
@property (assign, nonatomic, readwrite) GLKVector3 eyePosition;
@property (assign, nonatomic) GLKVector3 lookAtPosition;
@property (assign, nonatomic) GLKVector3 upVector;
@property (assign, nonatomic) float angle;

// BUFFER
@property (assign, nonatomic) GLuint mPositionBuffer;
@property (assign, nonatomic) GLuint mNormalBuffer;

@property (nonatomic , strong) UISwitch* mPauseSwitch;
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
    
    // 观察参数
    self.eyePosition = GLKVector3Make(0.0, 10.0, 10.0);
    self.lookAtPosition = GLKVector3Make(0.0, 0.0, 0.0);
    self.upVector = GLKVector3Make(0.0, 1.0, 0.0);
    
    // 灯光
    self.baseEffect = [[GLKBaseEffect alloc] init];
    self.baseEffect.light0.enabled = GL_TRUE;
    self.baseEffect.light0.position = GLKVector4Make(0.0f, 0.0f, 2.0f, 1.0f);
    self.baseEffect.light0.specularColor = GLKVector4Make(0.25f, 0.25f, 0.25f, 1.0f);
    self.baseEffect.light0.diffuseColor = GLKVector4Make(0.75f, 0.75f, 0.75f, 1.0f);
    self.baseEffect.lightingType = GLKLightingTypePerPixel;
    
    self.angle = 0.5;
    [self setMatrices];
    
    // 顶点缓存
    GLuint buffer;
    glGenVertexArraysOES(1, &_mPositionBuffer);
    glBindVertexArrayOES(_mPositionBuffer);
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(starshipPositions), starshipPositions, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(starshipNormals), starshipNormals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glEnable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    
    // 加载纹理图片
    NSString *path = [[NSBundle bundleForClass:[self class]]
                      pathForResource:@"image" ofType:@"png"];
    NSAssert(nil != path, @"Path to skybox image not found");
    NSError *error = nil;
    GLKTextureInfo* textureInfo = [GLKTextureLoader
                                   cubeMapWithContentsOfFile:path
                                   options:nil
                                   error:&error];
    if (error) {
        NSLog(@"error %@", error);
    }
    // 配置天空盒特效
    self.skyboxEffect = [[AGLKSkyboxEffect alloc] init];
    self.skyboxEffect.textureCubeMap.name = textureInfo.name;
    self.skyboxEffect.textureCubeMap.target = textureInfo.target;
    
    // 天空盒的长宽高
    self.skyboxEffect.xSize = 6.0f;
    self.skyboxEffect.ySize = 6.0f;
    self.skyboxEffect.zSize = 6.0f;
    
    //
    self.mPauseSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 30, 44, 44)];
    [self.view addSubview:self.mPauseSwitch];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setMatrices
{
    const GLfloat aspectRatio = (GLfloat)(self.view.bounds.size.width) / (GLfloat)(self.view.bounds.size.height);
    self.baseEffect.transform.projectionMatrix =
    GLKMatrix4MakePerspective(GLKMathDegreesToRadians(85.0f),
                              aspectRatio,
                              0.1f,
                              20.0f);
    
    {
        self.baseEffect.transform.modelviewMatrix =
        GLKMatrix4MakeLookAt(
                             self.eyePosition.x,
                             self.eyePosition.y,
                             self.eyePosition.z,
                             self.lookAtPosition.x,
                             self.lookAtPosition.y,
                             self.lookAtPosition.z,
                             self.upVector.x,
                             self.upVector.y,
                             self.upVector.z);
        
        // 增加角度
        self.angle += 0.01;
        
        // 调整眼睛的位置
        self.eyePosition = GLKVector3Make(-5.0f * sinf(self.angle),
                                          -5.0f,
                                          -5.0f * cosf(self.angle));
        
        // 调整观察的位置
        self.lookAtPosition = GLKVector3Make(0.0,
                                             1.5 + -5.0f * sinf(0.3 * self.angle),
                                             0.0);
        
    }
}


/**
 *  渲染场景代码
 */
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    if (self.mPauseSwitch.on) { // 暂停
//        return ;
    }
    
    glClearColor(0.5f, 0.1f, 0.1f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    if (!self.mPauseSwitch.on) { // 暂停
        [self setMatrices];
    }
    // 天空盒的眼睛
    self.skyboxEffect.center = self.eyePosition;
    self.skyboxEffect.transform.projectionMatrix = self.baseEffect.transform.projectionMatrix;
    self.skyboxEffect.transform.modelviewMatrix = self.baseEffect.transform.modelviewMatrix;
    
    [self.skyboxEffect prepareToDraw];
    glDepthMask(false);
    [self.skyboxEffect draw];
    glDepthMask(true);
    
    // DEBUG
    {
        GLenum error = glGetError();
        if(GL_NO_ERROR != error)
        {
            NSLog(@"GL Error: 0x%x", error);
        }
    }
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
    // 需要重新设置顶点数据，不需要缓存
    glBindVertexArrayOES(self.mPositionBuffer);
//    glBindBuffer(GL_ARRAY_BUFFER, self.mPositionBuffer);
//    glEnableVertexAttribArray(GLKVertexAttribPosition);
//    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);
//    glBindVertexArrayOES(self.mNormalBuffer);
//    glBindBuffer(GL_ARRAY_BUFFER, self.mNormalBuffer);
//    glEnableVertexAttribArray(GLKVertexAttribNormal);
//    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, NULL);

    // 绘制
    for(int i=0; i<starshipMaterials; i++)
    {
        // 设置材质
        self.baseEffect.material.diffuseColor = GLKVector4Make(starshipDiffuses[i][0], starshipDiffuses[i][1], starshipDiffuses[i][2], 1.0f);
        self.baseEffect.material.specularColor = GLKVector4Make(starshipSpeculars[i][0], starshipSpeculars[i][1], starshipSpeculars[i][2], 1.0f);
        
        [self.baseEffect prepareToDraw];
        
        glDrawArrays(GL_TRIANGLES, starshipFirsts[i], starshipCounts[i]);
    }
    
    // DEBUG
    {
        GLenum error = glGetError();
        if(GL_NO_ERROR != error)
        {
            NSLog(@"GL Error: 0x%x", error);
        }
    }
 
}
@end

