//
//  OSPositon.h
//  OSChart
//
//  Created by xu jie on 16/8/15.
//  Copyright © 2016年 xujie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
@interface OSPosition : NSObject
@property(nonatomic)GLfloat x;
@property(nonatomic)GLfloat y;
@property(nonatomic)GLfloat z;
+(instancetype)positionMakeX:(GLfloat)x Y:(GLfloat)y andZ:(GLfloat)z;

@end
