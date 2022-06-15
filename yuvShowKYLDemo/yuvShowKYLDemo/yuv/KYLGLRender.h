//
//  KYLGLRender.h
//  yuvShowKYLDemo
//
//  Created by yulu kong on 2019/7/27.
//  Copyright © 2019 yulu kong. All rights reserved.
//

#ifndef __KYLGLRENDER_H_
#define __KYLGLRENDER_H_


#import <Foundation/Foundation.h>

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/CAMediaTiming.h>
#import <QuartzCore/CATransform3D.h>
#import <Foundation/NSObject.h>

typedef  GLint EGLint;

typedef struct KYLYUVData
{
    unsigned int width;
    unsigned int height;
    uint8_t * data[3];
} *PYUVData;

struct KYLScreenParam
{
    unsigned int width;
    unsigned int height;

};


class GLRender
{
    typedef enum
    {
        VERTICAL = 0,
        HORIZONTAL
    }ORIENT_T;
    
public:
    GLRender();
    ~GLRender();
    
public:
    int nativeGLRender(PYUVData &yuvdata);
    void nativeGLRender(char *pFrame);
    int digitalRegionZoom(int bootom_x , int bootom_y, int top_x, int top_y);
    int close();
    bool setGLSurface(const int p_nWidth, const int p_nHeight, CAEAGLLayer *layer);
    
    
private:
    void render(const void *data);
    void render(PYUVData &yuvdata);
    void configGL();
    GLuint loadShader(GLenum shaderType, const char* pSource);
    GLuint createProgram(const char* pVertexSource, const char* pFragmentSource);
    bool setupGraphics(EGLint w, EGLint h) ;
    void setTexture(GLuint texture);
    
    void setupBuffers();
    void createBuffers();
    void releaseBuffers();
    
private:
    NSCondition  *m_lock;
    int mWidth, mGLSurfaceWidth;
    int mHeight, mGLSurfaceHeight;
    bool surface_ok;
    ORIENT_T mOrient;
    GLfloat *mSquareVertices;
    
private:
    EAGLContext *mContext;
    GLuint  mViewRenderbuffer;
    GLuint  mViewFramebuffer;
    CAEAGLLayer  *mSurface;
    GLuint  mGlProgram;
    
    GLuint m_texturePlanarY;
    GLuint m_texturePlanarU;
    GLuint m_texturePlanarV;
    
    GLint  mPositionLoc;
    GLint  mTexCoordLoc;
    
    GLint  mSamplerY;
    GLint  mSamplerU;
    GLint  mSamplerV;
    
    int mCurrentLayerWidth;
    int mCurrentLayerHeight;
};

#endif


