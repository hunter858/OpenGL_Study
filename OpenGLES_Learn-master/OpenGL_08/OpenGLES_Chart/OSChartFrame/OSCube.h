//
//  OSCube.h
//  OSChart
//
//  Created by xu jie on 16/8/15.
//  Copyright © 2016年 xujie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OSPosition.h"
@interface OSCube : NSObject
@property(nonatomic)GLfloat *vertex;
@property(nonatomic)GLuint number;

+(instancetype)cubeWidthPosition:(OSPosition*)position Width:(GLfloat)width Height:(GLfloat)height Length:(GLfloat)length;
@end
