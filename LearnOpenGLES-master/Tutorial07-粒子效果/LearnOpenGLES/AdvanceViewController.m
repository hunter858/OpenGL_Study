//
//  AdvanceViewController.m
//  LearnOpenGLES
//
//  Created by 林伟池 on 16/3/25.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "AdvanceViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "AGLKPointParticleEffect.h"


@interface AdvanceViewController ()


@property (nonatomic , strong) EAGLContext* mContext;

@property (strong, nonatomic) AGLKPointParticleEffect *particleEffect;
@property (assign, nonatomic) NSTimeInterval autoSpawnDelta;
@property (assign, nonatomic) NSTimeInterval lastSpawnTime;
@property (assign, nonatomic) NSInteger currentEmitterIndex;
@property (strong, nonatomic) NSArray *emitterBlocks;
@property (strong, nonatomic) GLKTextureInfo *ballParticleTexture;

@property (nonatomic , assign) long mElapseTime;
@end


@implementation AdvanceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mElapseTime = 0;
    
    //新建OpenGLES 上下文
    self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView* view = (GLKView *)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.mContext];
    
    
    NSString *path = [[NSBundle bundleForClass:[self class]]
                      pathForResource:@"ball" ofType:@"png"];
    NSAssert(nil != path, @"ball texture image not found");
    NSError *error = nil;
    self.ballParticleTexture = [GLKTextureLoader
                                textureWithContentsOfFile:path
                                options:nil
                                error:&error];
    
    
    self.particleEffect = [[AGLKPointParticleEffect alloc] init];
    self.particleEffect.texture2d0.name =
    self.ballParticleTexture.name;
    self.particleEffect.texture2d0.target =
    self.ballParticleTexture.target;
    
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    self.emitterBlocks = [NSArray arrayWithObjects:[^{  // 1
        self.autoSpawnDelta = 0.5f;
        
        self.particleEffect.gravity = AGLKDefaultGravity;
        
        float randomXVelocity = -0.5f + 1.0f *
        (float)random() / (float)RAND_MAX;
        
        [self.particleEffect
         addParticleAtPosition:GLKVector3Make(0.0f, 0.0f, 0.9f)
         velocity:GLKVector3Make(randomXVelocity, 1.0f, -1.0f)
         force:GLKVector3Make(0.0f, 9.0f, 0.0f)
         size:4.0f
         lifeSpanSeconds:3.2f
         fadeDurationSeconds:0.5f];
    } copy], [^{  // 2
        self.autoSpawnDelta = 0.05f;
        
        self.particleEffect.gravity = GLKVector3Make(
                                                     0.0f, 0.5f, 0.0f);
        
        for(int i = 0; i < 20; i++)
        {
            float randomXVelocity = -0.1f + 0.2f *
            (float)random() / (float)RAND_MAX;
            float randomZVelocity = 0.1f + 0.2f *
            (float)random() / (float)RAND_MAX;
            
            [self.particleEffect
             addParticleAtPosition:GLKVector3Make(0.0f, -0.5f, 0.0f)
             velocity:GLKVector3Make(
                                     randomXVelocity,
                                     0.0,
                                     randomZVelocity)
             force:GLKVector3Make(0.0f, 0.0f, 0.0f)
             size:16.0f
             lifeSpanSeconds:2.2f
             fadeDurationSeconds:3.0f];
        }
    } copy], [^{  // 3
        self.autoSpawnDelta = 0.5f;
        
        self.particleEffect.gravity = GLKVector3Make(
                                                     0.0f, 0.0f, 0.0f);
        
        for(int i = 0; i < 100; i++)
        {
            float randomXVelocity = -0.5f + 1.0f *
            (float)random() / (float)RAND_MAX;
            float randomYVelocity = -0.5f + 1.0f *
            (float)random() / (float)RAND_MAX;
            float randomZVelocity = -0.5f + 1.0f *
            (float)random() / (float)RAND_MAX;
            
            [self.particleEffect
             addParticleAtPosition:GLKVector3Make(0.0f, 0.0f, 0.0f)
             velocity:GLKVector3Make(
                                     randomXVelocity,
                                     randomYVelocity,
                                     randomZVelocity)
             force:GLKVector3Make(0.0f, 0.0f, 0.0f)
             size:4.0f
             lifeSpanSeconds:3.2f
             fadeDurationSeconds:0.5f];
        }
    } copy],[^{  // 4
        self.autoSpawnDelta = 3.2f;
        
        self.particleEffect.gravity = GLKVector3Make(
                                                     0.0f, 0.0f, 0.0f);
        
        for(int i = 0; i < 100; i++)
        {
            float randomXVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
            float randomYVelocity = -0.5f + 1.0f * (float)random() / (float)RAND_MAX;
            GLKVector3 velocity = GLKVector3Normalize(
                                                      GLKVector3Make(
                                                                     randomXVelocity,
                                                                     randomYVelocity,
                                                                     0.0f));
            
            [self.particleEffect
             addParticleAtPosition:GLKVector3Make(0.0f, 0.0f, 0.0f)
             velocity:velocity
             force:GLKVector3MultiplyScalar(velocity, -1.5f)
             size:4.0f
             lifeSpanSeconds:3.2f
             fadeDurationSeconds:0.1f];
        }
    } copy], nil];
    
    [self preparePointOfViewWithAspectRatio:
     CGRectGetWidth(self.view.bounds) / CGRectGetHeight(self.view.bounds)];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)update
{
    NSTimeInterval timeElapsed = self.timeSinceFirstResume;
    
//    NSLog(@"timeSinceLastUpdate: %f", self.timeSinceLastUpdate);
//    NSLog(@"timeSinceLastDraw: %f", self.timeSinceLastDraw);
//    NSLog(@"timeSinceFirstResume: %f", self.timeSinceFirstResume);
//    NSLog(@"timeSinceLastResume: %f", self.timeSinceLastResume);


    
    self.particleEffect.elapsedSeconds = timeElapsed;
    
    if(self.autoSpawnDelta < (timeElapsed - self.lastSpawnTime))
    {
        self.lastSpawnTime = timeElapsed;
        
        void(^emitterBlock)() = [self.emitterBlocks objectAtIndex: self.currentEmitterIndex];
        emitterBlock();
    }
}


//MVP矩阵
- (void)preparePointOfViewWithAspectRatio:(GLfloat)aspectRatio
{
    self.particleEffect.transform.projectionMatrix =
    GLKMatrix4MakePerspective(
                              GLKMathDegreesToRadians(85.0f),
                              aspectRatio,
                              0.1f,
                              20.0f);
    
    self.particleEffect.transform.modelviewMatrix =
    GLKMatrix4MakeLookAt(
                         0.0, 0.0, 1.0,   // Eye position
                         0.0, 0.0, 0.0,   // Look-at position
                         0.0, 1.0, 0.0);  // Up direction
}



- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    ++self.mElapseTime;
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    glClearColor(0.3, 0.3, 0.3, 1);
    
    [self.particleEffect prepareToDraw];
    [self.particleEffect draw];

}


- (BOOL)shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation !=
            UIInterfaceOrientationPortraitUpsideDown);
}


- (IBAction)takeSelectedEmitterFrom:(UISegmentedControl *)sender;
{
    self.currentEmitterIndex = [sender selectedSegmentIndex];
}






@end

