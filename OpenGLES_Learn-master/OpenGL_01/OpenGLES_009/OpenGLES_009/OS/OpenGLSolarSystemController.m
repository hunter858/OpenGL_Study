//
//  OpenGLSolarSystemController.m
//  OpenGLSolarSystemController
//
//  Created by mike on 9/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OpenGLSolarSystem.h" 
#import "OpenGLSolarSystemController.h"

@implementation OpenGLSolarSystemController

-(id)init
{
	[self initGeometry];					
	
	return self;
}

-(void)initGeometry
{
	m_Eyeposition[X_VALUE]=0.0;				//1
	m_Eyeposition[Y_VALUE]=0.0;
	m_Eyeposition[Z_VALUE]=10.0;
    
	m_Earth=[[Planet alloc] init:50 slices:50 radius:.5 squash:1.0];	//2
	[m_Earth setPositionX:0 Y:0.0 Z:0];			//3
	
	m_Month=[[Planet alloc] init:50 slices:50 radius:0.2 squash:1.0];	//4
	[m_Month setPositionX:0 Y:0.0 Z:0];
    
    m_Sun = [[Planet alloc]init:50 slices:50 radius:1 squash:1.0];
    [m_Sun setPositionX:0.0 Y:0.0 Z:0];
}

-(void)execute
{
	GLfloat paleYellow[]={1.0,1.0,0.3,1.0};			//1
	GLfloat white[]={1.0,1.0,1.0,1.0};			
	GLfloat cyan[]={1.0,1.0,1.0,1.0};
	GLfloat red[]={1.0,0.0,0.0,1.0};				//2
    GLfloat blue[]={0.0,0.0,1.0,1.0};
	static GLfloat angle=0.0;
	GLfloat orbitalIncrement=5.25;				//3
    
    static float monthAngle = 0;
    GLfloat monthInc = 0.2;
	GLfloat sunPos[4]={0.0,0.0,0.0,1.0};
				
    angle+=orbitalIncrement;
    monthAngle+= monthInc;
   

   // glTranslatef(-m_Eyeposition[X_VALUE],-m_Eyeposition[Y_VALUE],	//5
              //   -m_Eyeposition[Z_VALUE]);
	glPushMatrix();						//4
    
	glTranslatef(-m_Eyeposition[X_VALUE],-m_Eyeposition[Y_VALUE],	//5
                 -6);
    
   
    glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, red);	//15
    glLightfv(SS_SUNLIGHT,GL_POSITION,sunPos);		     // 设置灯光的位置
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, cyan);   // 设置材料正面面能发射的光的颜色
    glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, white); // 设置材料能发射的镜面光颜色
  
    glPushMatrix();
    glPushMatrix();
    glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, red);
    [self executePlanet:m_Sun];
    glPopMatrix();
    
    
    glRotatef(monthAngle, 0, 1, 0);
    glTranslatef(0,0,3);
    glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, blue);
    glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, blue);
  
    // glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, black);	//13
     [self executePlanet:m_Earth];
    
    glPushMatrix();
    glRotatef(angle, 0, 1, 0);
    glTranslatef(0,0,0.8);
    
     glMaterialfv(GL_FRONT_AND_BACK, GL_EMISSION, paleYellow);	//12
    [self executePlanet:m_Month];
   

    
    
    glPopMatrix();
    glPopMatrix();
    glPopMatrix();
    

   
}

-(void)executePlanet:(Planet *)planet
{
   
	GLfloat posX, posY, posZ;
		
	//glPushMatrix();
    
	[planet getPositionX:&posX Y:&posY Z:&posZ];			//17
	
	//glTranslatef(posX,posY,posZ);				//18
    
    
	[planet execute];						//19
    
	
	//glPopMatrix();
}

@end
