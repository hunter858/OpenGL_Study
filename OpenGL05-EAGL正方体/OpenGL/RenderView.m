//
//  RenderView.m
//  OpenGL
//
//  Created by pengchao on 2022/1/7.
//
#import "RenderView.h"
#import <GLKit/GLKit.h>

typedef struct {
    GLKVector3 positionCoord;
    GLKVector2 textureCoord;
    GLKVector3 normal;
} CCVertex;

static NSInteger const pointCount = 36;

CCVertex dataArray[] = {
    //前面
    {{-0.5, 0.5, 0.5},  {0, 1}, {0, 0, 1}},
    {{-0.5, -0.5, 0.5}, {0, 0}, {0, 0, 1}},
    {{0.5, 0.5, 0.5},   {1, 1}, {0, 0, 1}},
    {{-0.5, -0.5, 0.5}, {0, 0}, {0, 0, 1}},
    {{0.5, 0.5, 0.5},   {1, 1}, {0, 0, 1}},
    {{0.5, -0.5, 0.5},  {1, 0}, {0, 0, 1}},
    //上面
    {{0.5, 0.5, 0.5},   {1, 1}, {0, 1, 0}},
    {{-0.5, 0.5, 0.5},  {0, 1}, {0, 1, 0}},
    {{0.5, 0.5, -0.5},  {1, 0}, {0, 1, 0}},
    {{-0.5, 0.5, 0.5},  {0, 1}, {0, 1, 0}},
    {{0.5, 0.5, -0.5},  {1, 0}, {0, 1, 0}},
    {{-0.5, 0.5, -0.5}, {0, 0}, {0, 1, 0}},
    //下面
    {{0.5, -0.5, 0.5},  {1, 1}, {0, -1, 0}},
    {{-0.5, -0.5, 0.5}, {0, 1}, {0, -1, 0}},
    {{0.5, -0.5, -0.5}, {1, 0}, {0, -1, 0}},
    {{-0.5, -0.5, 0.5}, {0, 1}, {0, -1, 0}},
    {{0.5, -0.5, -0.5}, {1, 0}, {0, -1, 0}},
    {{-0.5, -0.5,-0.5},{0, 0},  {0, -1, 0}},
    //左面
    {{-0.5, 0.5, 0.5},  {1, 1}, {-1, 0, 0}},
    {{-0.5, -0.5, 0.5}, {0, 1}, {-1, 0, 0}},
    {{-0.5, 0.5, -0.5}, {1, 0}, {-1, 0, 0}},
    {{-0.5, -0.5, 0.5}, {0, 1}, {-1, 0, 0}},
    {{-0.5, 0.5, -0.5}, {1, 0}, {-1, 0, 0}},
    {{-0.5, -0.5,-0.5}, {0, 0}, {-1, 0, 0}},
    //右面
    {{0.5, 0.5, 0.5},   {1, 1}, {1, 0, 0}},
    {{0.5, -0.5, 0.5},  {0, 1}, {1, 0, 0}},
    {{0.5, 0.5, -0.5},  {1, 0}, {1, 0, 0}},
    {{0.5, -0.5, 0.5},  {0, 1}, {1, 0, 0}},
    {{0.5, 0.5, -0.5},  {1, 0}, {1, 0, 0}},
    {{0.5, -0.5, -0.5}, {0, 0}, {1, 0, 0}},
    //后面
    {{-0.5, 0.5, -0.5}, {0, 1}, {0, 0, -1}},
    {{-0.5, -0.5,-0.5}, {0, 0}, {0, 0, -1}},
    {{0.5, 0.5, -0.5},  {1, 1}, {0, 0, -1}},
    {{-0.5, -0.5,-0.5}, {0, 0}, {0, 0, -1}},
    {{0.5, 0.5, -0.5},  {1, 1}, {0, 0, -1}},
    {{0.5, -0.5, -0.5}, {1, 0}, {0, 0, -1}},
};


@interface RenderView ()<GLKViewDelegate>
{
    GLKView *_glkView;
    EAGLContext *_currentContext;
    GLKBaseEffect *_baseEffect;
    
    NSInteger _angle;
}
@property (nonatomic, assign) CCVertex *vertices;
@end

@implementation RenderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
        _glkView = [[GLKView alloc]initWithFrame:frame context:_currentContext];
        [self addSubview:_glkView];
        _glkView.delegate = self;
        /// 设置颜色缓冲区格式
        _glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
        /// 设置深度缓冲区格式
        _glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        glDepthRangef(1, 0);
        [EAGLContext setCurrentContext:_currentContext];
        [self addTimer];
        [self setupProgram];
        [self setupBindFrameBuffer];
    }
    return self;
}

  
- (void)setupBindFrameBuffer {
    
    GLuint attributeBuffer;
    glGenBuffers(1, &attributeBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attributeBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(CCVertex) * pointCount, dataArray
                 , GL_STATIC_DRAW);
    
    /// 顶点坐标
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(CCVertex), NULL +offsetof(CCVertex, positionCoord));
    
    ///纹理坐标
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(CCVertex), NULL+offsetof(CCVertex, textureCoord));
    
    ///法线
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(CCVertex), NULL+offsetof(CCVertex, normal));

}

-(void)addTimer {
    _angle = 0;
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
}

- (void)setupProgram {
    _baseEffect =[[GLKBaseEffect alloc]init];
    _baseEffect.colorMaterialEnabled = YES;
//    _baseEffect.useConstantColor = GL_TRUE; //
//    _baseEffect.constantColor = GLKVector4Make(0.0,0,0,1.0);

    _baseEffect.light0.enabled = YES;
    _baseEffect.light0.diffuseColor = GLKVector4Make(1.0, 1.0, 1.0, 0.5);

    //光源位置
    _baseEffect.light0.position = GLKVector4Make(0, 0.5, -0.5, 1.0);
    
    
    ///  加载贴图
    CGImageRef cgImage  = [UIImage imageNamed:@"tiger"].CGImage;
    
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft:@"1"};
    NSError *error ;
   GLKTextureInfo *imageInfo =  [GLKTextureLoader textureWithCGImage:cgImage options:options error:&error];
    if (error) {
        NSLog(@"laod image error: %@",error);
    }
    
    _baseEffect.texture2d0.enabled = GL_TRUE;
    _baseEffect.texture2d0.name =imageInfo.name;
    _baseEffect.texture2d0.target = imageInfo.target;
    
}

- (void)update {
    /// GLKMathDegreesToRadians(_angle); 帮助我们把角度转成弧度；
    ///GLKMatrix4MakeRotation 指定要旋转的弧度，分别在x、y、z 轴上；
    ///
    _angle = (_angle + 5) % 360;;
    _baseEffect.transform.modelviewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(_angle),0.3, 1, -0.7);
    [_glkView display];
}
 
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [EAGLContext setCurrentContext:_currentContext];

    glEnable(GL_DEPTH_TEST);
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    [_baseEffect prepareToDraw];
    glDrawArrays(GL_TRIANGLES, 0, pointCount);
}

@end
