//
//  OpenGL_SolarSystemViewController.m
//  BouncySquare
//
//  Created by mike on 9/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OpenGLSolarSystem.h" 
#import "OpenGLSolarSystemViewController.h"

@interface OpenGLSolarSystemViewController () 
{


}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@end


@implementation OpenGLSolarSystemViewController

@synthesize context = _context;
@synthesize effect = _effect;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    if (!self.context) 
    {
        NSLog(@"Failed to create ES context");
    }
    
   //
    self.view = [[GLKView alloc]initWithFrame:self.view.bounds context:self.context];
    GLKView *view = (GLKView *)self.view;
   // view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.context];

    
    m_SolarSystem=[[OpenGLSolarSystemController alloc] init];	
    
    [self setClipping];
    
    [self initLighting];
    
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glEnable(GL_DEPTH_TEST);

	glClearColor(0.0f,0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
	[m_SolarSystem execute];
}

-(void)initLighting
{
	GLfloat sunPos[]={0.0,0.0,0.0,1.0};			
	GLfloat posFill1[]={-15.0,15.0,0.0,1.0};			
	GLfloat posFill2[]={-10.0,-4.0,1.0,1.0};			
    
	GLfloat white[]={1.0,1.0,1.0,1.0};			
	GLfloat dimblue[]={0.0,0.0,.2,1.0};			
    
	GLfloat cyan[]={0.0,1.0,1.0,1.0};			
	GLfloat yellow[]={1.0,1.0,0.0,1.0};
	GLfloat dimmagenta[]={.75,0.0,.25,1.0};			
    
	GLfloat dimcyan[]={0.0,.5,.5,1.0};			
	
	//lights go here
	
	glLightfv(SS_SUNLIGHT,GL_POSITION,sunPos);
	glLightfv(SS_SUNLIGHT,GL_DIFFUSE,white);
	glLightfv(SS_SUNLIGHT,GL_SPECULAR,yellow);		
	
	glLightfv(SS_FILLLIGHT1,GL_POSITION,posFill1);
	glLightfv(SS_FILLLIGHT1,GL_DIFFUSE,dimblue);
	glLightfv(SS_FILLLIGHT1,GL_SPECULAR,dimcyan);	
    
	glLightfv(SS_FILLLIGHT2,GL_POSITION,posFill2);
	glLightfv(SS_FILLLIGHT2,GL_SPECULAR,dimmagenta);
	glLightfv(SS_FILLLIGHT2,GL_DIFFUSE,dimblue);
    
	//materials go here
	
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, cyan);
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, white);
    
	glLightf(SS_SUNLIGHT,GL_QUADRATIC_ATTENUATION,.001);
	
	glMaterialf(GL_FRONT_AND_BACK,GL_SHININESS,25);				
    
	glShadeModel(GL_SMOOTH);				
	glLightModelf(GL_LIGHT_MODEL_TWO_SIDE,0.0);
	
	glEnable(GL_LIGHTING);
	glEnable(SS_SUNLIGHT);
	glEnable(SS_FILLLIGHT1);
	glEnable(SS_FILLLIGHT2);
}


-(void)setClipping
{
	float aspectRatio;
	const float zNear = 0.1;
	const float zFar = 100;
	const float fieldOfView = 60.0;			
	GLfloat	size;
	
	CGRect frame = [[UIScreen mainScreen] bounds];		
    
	aspectRatio=(float)frame.size.width/(float)frame.size.height;					
	
	glMatrixMode(GL_PROJECTION);				
	glLoadIdentity();
    
	size = zNear * tanf(GLKMathDegreesToRadians (fieldOfView) / 2.0);	
    
	glFrustumf(-size, size, -size /aspectRatio, size /aspectRatio, zNear, zFar);
	glViewport(0, 0, frame.size.width, frame.size.height);		
	
	//glMatrixMode(GL_MODELVIEW);
}


@end
