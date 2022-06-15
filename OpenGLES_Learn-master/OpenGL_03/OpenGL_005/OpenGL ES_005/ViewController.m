//
//  ViewController.m
//  OpenGLES_004
//
//  Created by xu jie on 16/8/6.
//  Copyright © 2016年 xujie. All rights reserved.
//
/**
 *  学习目标 绘制移动的球体
 *
 *  第一步: 创建GLKViewController 控制器(在里面实现方法)
 *  第二步: 创建EAGContext 跟踪所有状态,命令和资源
 *  第三步: 生成球体的顶点坐标和颜色数据
 *  第三步: 清除命令
 *  第四步: 创建投影坐标系
 *  第五步: 创建对象坐标
 *  第六步: 导入顶点数据
 *  第七步: 导入颜色数据
 *  第八步: 绘制
 *  欢迎加群: 578734141 交流学习~
 *
 */
#import "ViewController.h"

#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES1/gl.h>

@interface ViewController ()
@property(nonatomic,strong)EAGLContext *eagContext;
@end

@implementation ViewController{
    GLfloat *_vertexArray;
    GLubyte *_colorsArray;
    
    GLint  m_Stacks, m_Slices;
    GLfloat  m_Scale;
    GLfloat m_Squash;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *imageView =  [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"bg.jpg"]];
    imageView.frame = self.view.bounds;
    [self.view addSubview:imageView];
    imageView.alpha = 0.5;
    [self createEagContext];
    [self configure];
    [self calculate];
    [self setClipping];
   
    
}
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    [self clear];
    [self initModelViewMatrix];
    [self loadVertexData];
    [self loadColorBuffer];
    [self draw];
}


/**
 *  创建EAGContext 跟踪所有状态,命令和资源
 */
- (void)createEagContext{
    self.eagContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES1];
    [EAGLContext setCurrentContext:self.eagContext];
}
/**
 *  配置view
 */

- (void)configure{
    GLKView *view = (GLKView*)self.view;
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.context = self.eagContext;
    
    
    
}

/**
 *  清除
 */
-(void)clear{
    glEnable(GL_DEPTH_TEST);
    glClearColor(1, 1, 1, 0.1);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
}

/**
 *  创建投影坐标
 */
- (void)initProjectionMatrix{
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
}

/**
 *  创建物体坐标
 */

-(void)initModelViewMatrix{
    
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    static GLfloat transY = 0.0;
    static GLfloat z=-2;
    static CGFloat scale = 1;
    static BOOL isBig = true;
    if (isBig){
        scale += 0.01;
    }else{
        scale -= 0.01;
    }
    if (scale>=1.5){
        isBig = false;
    }
    if (scale<=0.5){
        isBig = true;
    }
                //1
    static GLfloat spinX=0;
    static GLfloat spinY=0;
    glTranslatef(0.0, (GLfloat)(sinf(transY)/2.0), z);
    glRotatef(spinY, 0.0, 1.0, 0.0);
    glRotatef(spinX, 1.0, 0.0, 0.0);
    glScalef(scale, scale, scale);
    transY += 0.075f;
    spinY+=.25;
    spinX+=.25;
}
/**
 *  导出顶点坐标
 *  glVertexPointer 第一个参数:每个顶点数据的个数,第二个参数,顶点数据的数据类型,第三个偏移量，第四个顶点数组地址
 */
- (void)loadVertexData{
    glVertexPointer(3, GL_FLOAT, 0, _vertexArray);
    glEnableClientState(GL_VERTEX_ARRAY);
}

/**
 *  导入颜色数据
 */
- (void)loadColorBuffer{
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, _colorsArray);
    glEnableClientState(GL_COLOR_ARRAY);
}

/**
 *  导入索引数据
 */
-(void)draw{
    // 开启剔除面功能
    glEnable(GL_CULL_FACE);                                                             //3
    glCullFace(GL_BACK); // 剔除背面
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (m_Slices +1)*2*(m_Stacks-1)+2);
    
   // free(_vertexArray);
   // free(_colorsArray);
}

/**
 *  生成球体的顶点坐标和颜色数据
 */
-(void)calculate{
    unsigned int colorIncrment=0;				//1
    unsigned int blue=0;
    unsigned int red=255;
    unsigned int green = 0;
    static int big = 1;
    static float scale = 0;
    if (big){
       scale += 0.01;
    }else{
        scale -= 0.01;
    }
    
    
    if (scale >= 0.5){
        big = 0;
    }
    if (scale <= 0){
        big = 1;
    }
    m_Scale = 0.5 + scale;
    m_Slices = 100;
    m_Squash = 1;
    m_Stacks = 100;
    colorIncrment = 255/m_Stacks;					//2

        //vertices
    GLfloat *vPtr =  _vertexArray =
    (GLfloat*)malloc(sizeof(GLfloat) * 3 * ((m_Slices*2+2) * (m_Stacks)));	//3
        
        
        //color data
        
    GLubyte *cPtr = _colorsArray =
    (GLubyte*)malloc(sizeof(GLubyte) * 4 * ((m_Slices *2+2) * (m_Stacks)));	//4
        
    unsigned int	phiIdx, thetaIdx;
        
    //latitude
        
    for(phiIdx=0; phiIdx < m_Stacks; phiIdx++)		//5
    {

        float phi0 = M_PI * ((float)(phiIdx+0) * (1.0f/(float)( m_Stacks)) - 0.5f);
        float phi1 = M_PI * ((float)(phiIdx+1) * (1.0f/(float)( m_Stacks)) - 0.5f);
        float cosPhi0 = cos(phi0);			//8
        float sinPhi0 = sin(phi0);
        float cosPhi1 = cos(phi1);
        float sinPhi1 = sin(phi1);
        float cosTheta, sinTheta;
        for(thetaIdx=0; thetaIdx < m_Slices; thetaIdx++)
        {
            
                
            float theta = 2.0f*M_PI * ((float)thetaIdx) * (1.0f/(float)( m_Slices -1));
            cosTheta = cos(theta);
            sinTheta = sin(theta);
       
                
            vPtr [0] = m_Scale*cosPhi0 * cosTheta;
            vPtr [1] = m_Scale*sinPhi0*m_Squash;
            vPtr [2] = m_Scale*cosPhi0 * sinTheta;
                

                
            vPtr [3] = m_Scale*cosPhi1 * cosTheta;
            vPtr [4] = m_Scale*sinPhi1*m_Squash;
            vPtr [5] = m_Scale* cosPhi1 * sinTheta;
                
            cPtr [0] = red;
            cPtr [1] = green;
            cPtr [2] = blue;
            cPtr [4] = red;
            cPtr [5] = green;
            cPtr [6] = blue;
            cPtr [3] = cPtr[7] = 255;
                
            cPtr += 2*4;
                
            vPtr += 2*3;
        }
            
        //blue+=colorIncrment;
        red-=colorIncrment;
       // green += colorIncrment;
        }
    
}

/**
 *  设置窗口及投影坐标的位置
 */
-(void)setClipping
{
    float aspectRatio;
    const float zNear = .1;
    const float zFar = 1000;
    const float fieldOfView = 60.0;
    GLfloat    size;
    CGRect frame = [[UIScreen mainScreen] bounds];
    
    aspectRatio=(float)frame.size.width/(float)frame.size.height;
    [self initProjectionMatrix];
    size = zNear * tanf(GLKMathDegreesToRadians (fieldOfView) / 2.0);
    // 设置视图窗口的大小 和 坐标系统
    glFrustumf(-size, size, -size /aspectRatio, size /aspectRatio, zNear, zFar);
    glViewport(0, 0, frame.size.width, frame.size.height);
    
}







@end
