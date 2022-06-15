//
//  OSPositon.m
//  OSChart
//
//  Created by xu jie on 16/8/15.
//  Copyright © 2016年 xujie. All rights reserved.
//

#import "OSPosition.h"

@implementation OSPosition

+(instancetype)positionMakeX:(GLfloat)x Y:(GLfloat)y andZ:(GLfloat)z{
    OSPosition *positon = [[OSPosition alloc]init];
    positon.x =  x;
    positon.y = y;
    positon.z = z;
    return  positon;
}

@end
