//
//  RenderView.m
//  OpenGL
//
//  Created by pengchao on 2022/1/7.
//
#import "RenderView.h"
#import <GLKit/GLKit.h>

GLfloat vertices[]  = {
    0.5f, -0.5f, -1.0f,     1.0f, 0.0f, //右下角A
    -0.5f, 0.5f, -1.0f,     0.0f, 1.0f, //左上角B
    -0.5f, -0.5f, -1.0f,    0.0f, 0.0f, //左下角C
    
    0.5f, 0.5f, -1.0f,      1.0f, 1.0f, //右上角D
    -0.5f, 0.5f, -1.0f,     0.0f, 1.0f, //左上角B
    0.5f, -0.5f, -1.0f,     1.0f, 0.0f, //右下角A
};

@interface RenderView ()<GLKViewDelegate>
{
    GLKView *_glkView;
    EAGLContext *_currentContext;
    GLKBaseEffect *_baseEffect;
}
@end

@implementation RenderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
        _glkView = [[GLKView alloc]initWithFrame:frame context:_currentContext];
        [self addSubview:_glkView];
        _glkView.delegate = self;
        /// 设置颜色缓冲区格式
        _glkView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
        /// 设置深度缓冲区格式
        _glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
        [EAGLContext setCurrentContext:_currentContext];
        [self setupProgram];
        [self loadImage];
        [self renderlayer];
    }
    return self;
}



- (void)setupProgram {
    _baseEffect = [[GLKBaseEffect alloc]init];
    
}
- (void)loadImage{
    NSDictionary *option = @{GLKTextureLoaderOriginBottomLeft:@(1)};
    CGImageRef image = [[UIImage imageNamed:@"image"] CGImage];
    NSError *error;
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:image options:option error:&error];
    _baseEffect.texture2d0.enabled = GL_TRUE ;
    _baseEffect.texture2d0.name = textureInfo.name;
    _baseEffect.texture2d0.target = textureInfo.target;
}

- (void)renderlayer{

    GLuint attributeBuffer;
    glGenBuffers(1, &attributeBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, attributeBuffer);
    
    GLint num = sizeof(vertices);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_DYNAMIC_DRAW);
    
    ///顶点,（向定位置填充数据）
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL);
    
    ///纹理坐标 （向纹理坐标填充数据）
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, (float *)NULL+3);
    
}




- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    [EAGLContext setCurrentContext:_currentContext];
    [_baseEffect prepareToDraw];
    glClearColor(0, 0, 0, 1.0);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
}


@end
