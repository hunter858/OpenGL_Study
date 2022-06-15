//
//  OSCube.m
//  OSChart
//
//  Created by xu jie on 16/8/15.
//  Copyright © 2016年 xujie. All rights reserved.
//

#import "OSCube.h"
#import <GLKit/GLKit.h>

@implementation OSCube
+(instancetype)cubeWidthPosition:(OSPosition*)position Width:(GLfloat)width Height:(GLfloat)height Length:(GLfloat)length{
    GLfloat x = position.x;
    GLfloat y = position.y;
    GLfloat z = position.z;
    OSPosition *position0 = [OSPosition positionMakeX:x-width/2.0 Y:y+height andZ:z+length/2.0];

    OSPosition *position1 = [OSPosition positionMakeX:x+width/2.0 Y:y+height andZ:z+length/2.0];

    OSPosition *position2 = [OSPosition positionMakeX:x-width/2.0 Y:y andZ:z+length/2.0];

    OSPosition *position3 = [OSPosition positionMakeX:x+width/2.0 Y:y andZ:z+length/2.0];
   
    OSPosition *position4 = [OSPosition positionMakeX:x-width/2.0 Y:y+height andZ:z-length/2.0];
    OSPosition *position5 = [OSPosition positionMakeX:x+width/2.0 Y:y+height andZ:z-length/2.0];
    OSPosition *position6 = [OSPosition positionMakeX:x-width/2.0 Y:y andZ:z-length/2.0];
    OSPosition *position7 = [OSPosition positionMakeX:x+width/2.0 Y:y andZ:z-length/2.0];
    OSCube* cube = [[OSCube alloc]init];
    cube.number = 216;
    
    cube.vertex = malloc(sizeof(GLfloat)*cube.number);
    NSArray * array = @[position0,position1,position2,position3,position4,position5,position6,position7];
    NSArray * indexs = @[@1,@0,@2,
                         @1,@2,@3,
                         @1,@3,@7,
                         @1,@7,@5,
                         @1,@5,@4,
                         @1,@4,@0,
                         @6,@7,@5,
                         @6,@5,@4,
                         @6,@0,@4,
                         @6,@2,@0,
                         @6,@7,@3,
                         @6,@3,@2];
    for (int i=0;i< indexs.count ;i++){
        OSPosition *position = array[[indexs[i]integerValue]];
        
        cube.vertex[i*6] = position.x;
        cube.vertex[i*6+1] = position.y;
        cube.vertex[i*6+2] = position.z;
        switch (i/6) {
            case 0:
                cube.vertex[i*6+3] = 0;
                cube.vertex[i*6+4] = 0;
                cube.vertex[i*6+5] = 1;
                break;
            case 1:
                cube.vertex[i*6+3] = 1;
                cube.vertex[i*6+4] = 0;
                cube.vertex[i*6+5] = 0;
                    
                break;
            case 2:
                cube.vertex[i*6+3] = 0;
                cube.vertex[i*6+4] = 1;
                cube.vertex[i*6+5] = 0;
                   
                break;
            case 3:
                cube.vertex[i*6+3] = 0;
                cube.vertex[i*6+4] = 0;
                cube.vertex[i*6+5] = -1;
                break;
            case 4:
                cube.vertex[i*6+3] = 0;
                cube.vertex[i*6+4] = -1;
                cube.vertex[i*6+5] = 0;
                   
                break;
            case 5:
                cube.vertex[i*6+3] = -1;
                cube.vertex[i*6+4] = 0;
                cube.vertex[i*6+5] = 0;
                break;
                    
            default:
                break;
           
        }
        
    
        
    }
    
//    
//    for (int i =0 ;i<cube.number;i+= 3){
//        switch (i/18) {
//            case 0:
//                cube.normal[i] = 0;
//                cube.normal[i+1] = 0;
//                cube.normal[i+2] = 1;
//                break;
//            case 1:
//                cube.normal[i] = 1;
//                cube.normal[i+1] = 0;
//                cube.normal[i+2] = 0;
//                break;
//            case 2:
//                cube.normal[i] = 0;
//                cube.normal[i+1] = 1;
//                cube.normal[i+2] = 0;
//                break;
//            case 3:
//                cube.normal[i] = 0;
//                cube.normal[i+1] = 0;
//                cube.normal[i+2] = -1;
//                break;
//            case 4:
//                cube.normal[i] = 0;
//                cube.normal[i+1] = -1;
//                cube.normal[i+2] = 0;
//                break;
//            case 5:
//                cube.normal[i] = -1;
//                cube.normal[i+1] = 0;
//                cube.normal[i+2] = 0;
//                break;
//
//            default:
//                break;
//        }
//    };
    return cube;
}
-(void)dealloc{
    free(self.vertex);
    
}

@end
