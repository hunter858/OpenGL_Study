//
//  os_cube.h
//  OpenGLES_004
//
//  Created by xu jie on 16/8/6.
//  Copyright © 2016年 xujie. All rights reserved.
//

#ifndef os_cube_h
#define os_cube_h
static const GLfloat cubeVertices[] =
{
    -0.5, 0.5, 0.5,
    0.5, 0.5, 0.5,
    0.5,-0.5, 0.5,
    -0.5,-0.5, 0.5,
    -0.5, 0.5,-0.5,
    0.5, 0.5,-0.5,
    0.5,-0.5,-0.5,
    -0.5,-0.5,-0.5,
    //1
};
static const GLubyte cubeColors[] = {
    255, 255,   0, 255,
    0,   255, 255, 255,
    0,     0,   0,   0,
    255,   0, 255, 255,
    255, 255,   0, 255,
    0,   255, 255, 255,
    0,     0,   0,   0,
    255,   0, 255, 255,
};
//2
static const GLubyte tfan1[6 * 3] =
{
    1,0,3,
    1,3,2,
    1,2,6,
    1,6,5,
    1,5,4,
    1,4,0
};
//3
//4
static const GLubyte tfan2[6 * 3] =
{
    7,4,5,
    7,5,6,
    7,6,2,
    7,2,3,
    7,3,0,
    7,0,4
};


#endif /* os_cube_h */
