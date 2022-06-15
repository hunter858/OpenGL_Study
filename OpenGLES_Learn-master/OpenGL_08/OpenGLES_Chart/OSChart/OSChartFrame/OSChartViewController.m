//
//  GameViewController.m
//  OSChart
//
//  Created by xu jie on 16/8/15.
//  Copyright © 2016年 xujie. All rights reserved.
//

#import "OSChartViewController.h"
#import <OpenGLES/ES2/glext.h>
#import "OSCube.h"


#define BUFFER_OFFSET(i) ((char *)NULL + (i))
#define WIDTH   0.1

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};


@interface OSChartViewController () {
   
    float _rotation;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _normaBuffer;
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (strong,nonatomic) GLKBaseEffect *lightEffect;
@property (strong, nonatomic) NSMutableArray *values;
@property (strong,nonatomic) NSArray *targetValues;
@property (nonatomic)BOOL isRotation;

- (void)setupGL;
- (void)tearDownGL;


@end

@implementation OSChartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
}




- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.0f, 1.0f, 1.0f);
    self.lightEffect = [[GLKBaseEffect alloc]init];
    self.lightEffect.light0.enabled = GL_TRUE;
    self.lightEffect.light0.diffuseColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
    glEnable(GL_DEPTH_TEST);
  
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;
    
   }

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    static GLfloat radious = 0;
    radious += 1;
    if (radious>=65){
        radious = 65.0f;
       
        
    }
    for (int i = 0; i < self.targetValues.count;i++){
        if ([self.targetValues[i]floatValue] > [self.values[i]floatValue]){
            self.values[i] = @([self.values[i]floatValue]+5);
        }
    }
    if (self.isRotation){
        _rotation += self.timeSinceLastUpdate * 0.5f;
    }
    
   
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(radious), aspect, 0.1f, 10.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    self.effect.transform.modelviewMatrix = baseModelViewMatrix;
   
    
}


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    CGFloat width = 2.0 /self.values.count ;
    for (int i=0; i< self.values.count;i++){
        
        CGFloat value = 2.0/ (CGFloat)self.view.bounds.size.height *[self.values[i]floatValue];
        switch (i) {
            case 0:
                 self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.0f, 0.0f, 1.0f);
                break;
            case 1:
                self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.0f, 1.0f, 1.0f);
                break;
            case 2:
                self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f);
                break;
            case 3:
                self.effect.light0.diffuseColor = GLKVector4Make(0.0f, 1.0f, 0.0f, 1.0f);
                break;
            case 4:
                self.effect.light0.diffuseColor = GLKVector4Make(0.0f, 0.0f, 1.0f, 1.0f);
                break;
            case 5:
                self.effect.light0.diffuseColor = GLKVector4Make(0.0f, 1.0f, 1.0f, 1.0f);
                break;
            case 6:
                self.effect.light0.diffuseColor = GLKVector4Make(0.1f, 0.3f, 1.0f, 1.0f);
                break;
            case 7:
                self.effect.light0.diffuseColor = GLKVector4Make(0.9f, 0.1f, 0.3f, 1.0f);
                break;
            case 8:
                self.effect.light0.diffuseColor = GLKVector4Make(1, 0.3f, 0.4f, 1.0f);
                break;
            case 9:
                self.effect.light0.diffuseColor = GLKVector4Make(0.6f, 0.1f, 0.3f, 1.0f);
                break;
            case 10:
                self.effect.light0.diffuseColor = GLKVector4Make(0.5f, 0.1f, 7, 1.0f);
                break;
                
            default:
                break;
        }
      
        [self.effect prepareToDraw];
        [self drawCubePostitonX: -1 + i*width Max:value width:width-0.1];
    }

}

-(void)drawCubePostitonX:(CGFloat)x Max:(CGFloat)max width:(CGFloat)width{
    
    OSCube *cube1 = [OSCube cubeWidthPosition:[OSPosition positionMakeX:x Y:-1 andZ:0] Width:width Height:max Length:width];
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, cube1.number*sizeof(CGFloat), cube1.vertex, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    glDrawArrays(GL_TRIANGLES, 0, 36);
    glDeleteBuffers(1, &_vertexBuffer);
   

    
}

// MARK: - 下面是主要的方法
- (void)loadData:(NSArray*)data{
    self.targetValues = data;
    self.values = [NSMutableArray arrayWithArray:self.targetValues];
    for (int i=0;i<self.values.count;i++){
        self.values[i] = @(0);
    }
  
    
}
-(void)startRotation{
    self.isRotation = true;
    _rotation = 0;
}
-(void)stopRotation{
    self.isRotation = false;
}

-(instancetype)initWithChartData:(NSArray*)chartData{
    if (self = [super init]){
        [self loadData:chartData];
    }
    return  self;
}


@end

