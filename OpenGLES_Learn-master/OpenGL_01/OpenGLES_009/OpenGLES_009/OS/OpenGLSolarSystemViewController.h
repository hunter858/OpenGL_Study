//
//  OpenGLSolarSystemViewController.h
//  BouncySquare
//
//  Created by mike on 9/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#import "OpenGLSolarSystem.h" 
#import "OpenGLSolarSystemController.h"

@interface OpenGLSolarSystemViewController : GLKViewController
{
    OpenGLSolarSystemController *m_SolarSystem;
    
};

-(void)viewDidLoad;
-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect;
-(void)setClipping;
-(void)initLighting;
@end
