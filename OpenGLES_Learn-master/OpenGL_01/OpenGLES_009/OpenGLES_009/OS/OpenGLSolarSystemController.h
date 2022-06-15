//
//  OpenGLSolarSystemController.h
//  OpenGLSolarSystemController
//
//  Created by mike on 9/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "Planet.h"

#define X_VALUE								0
#define Y_VALUE								1
#define Z_VALUE								2


@interface OpenGLSolarSystemController : NSObject 
{
	Planet *m_Earth;
	Planet *m_Sun;
    Planet *m_Month;
	GLfloat	m_Eyeposition[3];
}

-(void)execute;
-(void)executePlanet:(Planet *)planet;
-(id)init;
-(void)initGeometry;

@end

