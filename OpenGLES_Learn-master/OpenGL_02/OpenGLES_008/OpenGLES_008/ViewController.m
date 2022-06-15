//
//  ViewController.m
//  OpenGLES_004
//
//  Created by xu jie on 16/8/6.
//  Copyright © 2016年 xujie. All rights reserved.
//
/**
 *  学习目标 绘制移动的球体 添加灯光
 *
 *  第一步: 创建GLKViewController 控制器(在里面实现方法)
 *  第二步: 创建EAGContext 跟踪所有状态,命令和资源
 *  第三步: 生成球体的顶点坐标和颜色数据
 *  第四步: 创建投影坐标系
 *  第五步: 创建视景体
 *  第六步: 添加多个光源
 *  第七步: 清除命令
 *  第八步: 创建对象坐标
 *  第九步: 导入顶点数据
 *  第十步: 导入颜色数据
 *  第十一步: 绘制
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
    GLfloat *_NormalArray;
    
    GLint  m_Stacks, m_Slices;
    GLfloat  m_Scale;
    GLfloat m_Squash;
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    UIImageView *imageView =  [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"1.jpg"]];
//    imageView.frame = self.view.bounds;
//    [self.view addSubview:imageView];
//    imageView.alpha = 0.5;
    [self createEagContext];
    [self configure];
    [self calculate];
    
    [self initProjectionMatrix];
    [self setClipping];
    
    
     [self initLighting];
    
    
    
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
     glEnableClientState(GL_VERTEX_ARRAY); // 开启顶点模式
     glVertexPointer(3, GL_FLOAT, 0, _vertexArray);
   
    
    glEnableClientState(GL_NORMAL_ARRAY); // 开启法线模式
    glNormalPointer(GL_FLOAT, 0, _NormalArray);
}

/**
 *  导入颜色数据
 */
- (void)loadColorBuffer{
    glEnableClientState(GL_COLOR_ARRAY); // 开启颜色模式
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, _colorsArray);
    
}

/**
 *  导入索引数据
 */
-(void)draw{
    // 开启剔除面功能
    glEnable(GL_CULL_FACE);                                                             //3
    glCullFace(GL_BACK); // 剔除背面
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (m_Slices +1)*2*(m_Stacks-1)+2);
    
   
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
    
    //
    GLfloat *nPtr = _NormalArray =
    (GLfloat*)malloc(sizeof(GLfloat) * 3 * ((m_Slices*2+2) * (m_Stacks)));	//4
    
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
            
            // Normal pointers for lighting
            
            nPtr[0] = cosPhi0 * cosTheta; 	//2
            nPtr[1] = sinPhi0;
            nPtr[2] = cosPhi0 * sinTheta;
            
            nPtr[3] = cosPhi1 * cosTheta; 	//3
            nPtr[4] = sinPhi1;
            nPtr[5] = cosPhi1 * sinTheta;
            
            cPtr += 2*4;
            
            vPtr += 2*3;
            
            nPtr += 2*3;
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
   
    size = zNear * tanf(GLKMathDegreesToRadians (fieldOfView) / 2.0);
    // 设置视图窗口的大小 和 坐标系统
    glFrustumf(-size, size, -size /aspectRatio, size /aspectRatio, zNear, zFar);
    glViewport(0, 0, frame.size.width, frame.size.height);
    
}
/**
 *  创建光源
 */

-(void)initLighting
{
    // 创建灯光的位置
    GLfloat posMain[]={5.0,4.0,6.0,1.0};
    GLfloat posFill1[]={-15.0,15.0,0.0,1.0};
    GLfloat posFill2[]={-10.0,-4.0,1.0,1.0};
    GLfloat white[]={1.0,1.0,1.0,1.0};

    
   // 定义几种颜色值
    GLfloat dimblue[]={0.0,0.0,.2,1.0};
    GLfloat cyan[]={0.0,1.0,1.0,1.0};
    GLfloat yellow[]={1.0,1.0,0.0,1.0};

    GLfloat dimmagenta[]={.75,0.0,.25,1.0};
    GLfloat dimcyan[]={0.0,.5,.5,1.0};
    //设置反射光的位置和颜色
    glLightfv(GL_LIGHT0,GL_POSITION,posMain);
    glLightfv(GL_LIGHT0,GL_DIFFUSE,white);
    // 设置镜面光的颜色，它的光源和反射光是同一个光源
    glLightfv(GL_LIGHT0,GL_SPECULAR,yellow);
    
    // 设置光源2的位置和类型
    glLightfv(GL_LIGHT1,GL_POSITION,posFill1);
    glLightfv(GL_LIGHT1,GL_DIFFUSE,dimblue);
    glLightfv(GL_LIGHT1,GL_SPECULAR,dimcyan);
    
    // 设置光源3 的位置和类型以及
    glLightfv(GL_LIGHT2,GL_POSITION,posFill2);
    glLightfv(GL_LIGHT2,GL_SPECULAR,dimmagenta);
    glLightfv(GL_LIGHT2,GL_DIFFUSE,dimblue);
    //设置衰减因子
    glLightf(GL_LIGHT2,GL_QUADRATIC_ATTENUATION,.005);
    
    //设置材料在反射光下的颜色
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, cyan);
    
    // 设置材料在镜面光下的颜色
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, white);
    
    //
    glMaterialf(GL_FRONT_AND_BACK,GL_SHININESS,25);
    
    // 设置光照模式 GL_SMOOTH 代表均匀的颜色涂在表面上
    glShadeModel(GL_SMOOTH);
    glLightModelf(GL_LIGHT_MODEL_TWO_SIDE,0.0);
    
    // 开启灯光模式
    glEnable(GL_LIGHTING);
    
    // 打开灯光123
    glEnable(GL_LIGHT0);
    glEnable(GL_LIGHT1);
    glEnable(GL_LIGHT2);
  
}







@end
