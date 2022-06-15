//
//  KYLGLRender.m
//  yuvShowKYLDemo
//
//  Created by yulu kong on 2019/7/27.
//  Copyright © 2019 yulu kong. All rights reserved.
//

#import "KYLGLRender.h"


#define   LOGI  printf("GLRender: "); printf
#define   LOGE  printf("GLRender: "); printf
#define   eglGetError glGetError


#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>

typedef   GLint  EGLint;
#define   EGL_SUCCESS GL_NO_ERROR

const int VERTEX_STRIDE = 6 * sizeof(GLfloat);

const GLfloat squareVertices[] = {
    1.0f, -1.0f, 0.0f, 1.0f,    // Position 0
    1.0f, 1.0f,                 // TexCoord 0
    1.0f, 1.f, 0.0f, 1.0f,      // Position 1
    1.0f,  0.0f,                // TexCoord 1
    -1.0f, -1.0f, 0.0f, 1.0f,   // Position 2
    0.0f,  1.0f,                // TexCoord 2
    -1.0f,  1.f, 0.0f, 1.0f,    // Position 3
    0.0f,  0.0f,                // TexCoord 3
};

//Vertext shader language
static const char gVertexShader[] =
"attribute vec4 a_Position;\n"
"attribute vec2 a_texCoord;\n"
"varying vec2 v_texCoord;\n"
"void main() {\n"
"  gl_Position = a_Position;\n"
"  v_texCoord = a_texCoord;\n"
"}\n";

//Fragment shader language
static const char gFragmentShader[] =
"varying lowp vec2 v_texCoord;\n"
"uniform sampler2D SamplerY;\n"
"uniform sampler2D SamplerU;\n"
"uniform sampler2D SamplerV;\n"
"void main(void)\n"
"{\n"
"mediump vec3 yuv;\n"
"lowp vec3 rgb;\n"
"yuv.x = texture2D(SamplerY, v_texCoord).r;\n"
"yuv.y = texture2D(SamplerU, v_texCoord).r - 0.5;\n"
"yuv.z = texture2D(SamplerV, v_texCoord).r - 0.5;\n"
"rgb = mat3( 1,   1,   1,\n"
"0,       -0.39465,  2.03211,\n"
"1.13983,   -0.58060,  0) * yuv;\n"
"gl_FragColor = vec4(rgb, 1);\n"
"}\n";

GLRender::GLRender()
:surface_ok(false)
,mContext(NULL)
,mOrient(VERTICAL)
,mViewRenderbuffer(NULL)
,mViewFramebuffer(NULL)
{
    mSquareVertices = (GLfloat *)malloc(sizeof(squareVertices));
    memcpy(mSquareVertices,squareVertices,sizeof(squareVertices));
    m_lock = [[NSCondition alloc] init];
}

GLRender::~GLRender()
{
    this->releaseBuffers();
    free(mSquareVertices);
}

int GLRender::close()
{
    [m_lock lock];
    if (surface_ok)
    {
        if (mContext)
        {
            glClearColor(0, 0, 0, 0);
            glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
            [mContext  presentRenderbuffer:GL_RENDERBUFFER];
            
            [EAGLContext setCurrentContext:mContext];
            this->releaseBuffers();
            [EAGLContext setCurrentContext:nil];
            
            if (mContext){
                mContext = nil;
            }
        }
        mSurface = NULL;
        surface_ok = false ;
    }
    [m_lock unlock];
    return 0;
}

GLuint GLRender::loadShader(GLenum shaderType, const char* pSource) {
    GLuint shader = glCreateShader(shaderType);
    if (shader) {
        glShaderSource(shader, 1, &pSource, NULL);
        glCompileShader(shader);
        GLint compiled = 0;
        
        glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
        if (!compiled) {
            GLint infoLen = 0;
            glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLen);
            
            if (infoLen) {
                char* buf = (char*) malloc(infoLen);
                if (buf != NULL) {
                    glGetShaderInfoLog(shader, infoLen, NULL, buf);
                    LOGE("Could not compile shader %d:\n%s\n", shaderType, buf);
                    free(buf);
                }
                glDeleteShader(shader);
                shader = 0;
            }
        }
        
    }
    return shader;
}


GLuint GLRender::createProgram(const char* pVertexSource, const char* pFragmentSource)
{
    GLuint program = glCreateProgram();
    if (program) {
        GLuint vertexShader = loadShader(GL_VERTEX_SHADER, pVertexSource);
        if (!vertexShader) {
            return 0;
        }else{
            glAttachShader(program, vertexShader);
        }
        
        GLuint pixelShader = loadShader(GL_FRAGMENT_SHADER, pFragmentSource);
        if (!pixelShader) {
            return 0;
        }else{
            glAttachShader(program, pixelShader);
        }
        
        glLinkProgram(program);
        GLint linkStatus = GL_FALSE;
        glGetProgramiv(program, GL_LINK_STATUS, &linkStatus);
        
        if (linkStatus != GL_TRUE) {
            GLint bufLength = 0;
            glGetProgramiv(program, GL_INFO_LOG_LENGTH, &bufLength);
            if (bufLength) {
                char* buf = (char*) malloc(bufLength);
                if (buf) {
                    glGetProgramInfoLog(program, bufLength, NULL, buf);
                    LOGE("Could not link program:\n%s\n", buf);
                    free(buf);
                }
            }
            glDeleteProgram(program);
            program = 0;
        }
    }
    return program;
}

void GLRender::setupBuffers()
{
    glDisable(GL_DEPTH_TEST);
    
    mPositionLoc = glGetAttribLocation(mGlProgram, "a_Position");
    glEnableVertexAttribArray(mPositionLoc);
    glVertexAttribPointer(mPositionLoc, 4, GL_FLOAT,GL_FALSE, VERTEX_STRIDE, mSquareVertices);
    
    mTexCoordLoc = glGetAttribLocation(mGlProgram, "a_texCoord");
    glEnableVertexAttribArray(mTexCoordLoc);
    glVertexAttribPointer(mTexCoordLoc, 2, GL_FLOAT, GL_FALSE, VERTEX_STRIDE, &mSquareVertices[4]);
    
    this->createBuffers();
}

void GLRender::createBuffers()
{
    [EAGLContext setCurrentContext:mContext];
    
    //Create render buffer
    glGenRenderbuffers(1, &mViewRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, mViewRenderbuffer);
    
    //Create frame buffer
    glGenFramebuffers(1, &mViewFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, mViewFramebuffer);
    
    //Create viewport
    [mContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:mSurface];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &mGLSurfaceWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &mGLSurfaceHeight);
    glViewport(0.0, 0.0, mGLSurfaceWidth, mGLSurfaceHeight);
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, mViewRenderbuffer);
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE){
        NSLog(@"Failure with framebuffer generation");
    }
}

void GLRender::releaseBuffers()
{
    if (mViewFramebuffer){
        glDeleteFramebuffers(1, &mViewFramebuffer);
        mViewFramebuffer = 0;
    }
    
    if (mViewFramebuffer){
        glDeleteRenderbuffers(1, &mViewRenderbuffer);
        mViewRenderbuffer = 0;
    }
}

bool GLRender::setupGraphics(EGLint w, EGLint h)
{
    mGlProgram = createProgram(gVertexShader, gFragmentShader);
    if (!mGlProgram) {
        LOGE("Could not create program.");
        return false;
    }
    
    // Get sampler location
    mSamplerY = glGetUniformLocation(mGlProgram, "SamplerY");
    mSamplerU = glGetUniformLocation(mGlProgram, "SamplerU");
    mSamplerV = glGetUniformLocation(mGlProgram, "SamplerV");
    
    glUseProgram(mGlProgram);
    glGenTextures(1, &m_texturePlanarY);
    glGenTextures(1, &m_texturePlanarU);
    glGenTextures(1, &m_texturePlanarV);
    
    glActiveTexture(GL_TEXTURE0);
    setTexture(m_texturePlanarY);
    glUniform1i(mSamplerY, 0);
    
    glActiveTexture(GL_TEXTURE1);
    setTexture(m_texturePlanarU);
    glUniform1i(mSamplerU, 1);
    
    glActiveTexture(GL_TEXTURE2);
    setTexture(m_texturePlanarV);
    glUniform1i(mSamplerV, 2);
    
    surface_ok = true;
    return true;
}

void GLRender::nativeGLRender(char *pFrame)
{
    [m_lock lock];
    this->configGL();
    
    if (surface_ok)
    {
        glViewport(0, 0, mGLSurfaceWidth, mGLSurfaceHeight);
        
        mPositionLoc  = glGetAttribLocation(mGlProgram, "a_Position");
        mTexCoordLoc     = glGetAttribLocation(mGlProgram, "a_texCoord");
        
        glEnableVertexAttribArray(mPositionLoc);
        glVertexAttribPointer(mPositionLoc, 4, GL_FLOAT,GL_FALSE, VERTEX_STRIDE, mSquareVertices);
        
        // Load the texture coordinate
        glEnableVertexAttribArray(mTexCoordLoc);
        glVertexAttribPointer(mTexCoordLoc, 2, GL_FLOAT, GL_FALSE, VERTEX_STRIDE, &mSquareVertices[4]);
        
        glDisable(GL_BLEND);
        glActiveTexture(GL_TEXTURE0);
        setTexture(m_texturePlanarY);
        glUniform1i(mSamplerY, 0);
        
        glActiveTexture(GL_TEXTURE1);
        setTexture(m_texturePlanarU);
        glUniform1i(mSamplerU, 1);
        
        glActiveTexture(GL_TEXTURE2);
        setTexture(m_texturePlanarV);
        glUniform1i(mSamplerV, 2);
        
        render(pFrame);
    }
    [m_lock unlock];
}
int GLRender::nativeGLRender(PYUVData &yuvdata)
{
    [m_lock lock];
    if(mCurrentLayerHeight != mSurface.bounds.size.height && mCurrentLayerWidth != mSurface.bounds.size.width){
        mCurrentLayerWidth = mSurface.bounds.size.width;
        mCurrentLayerHeight = mSurface.bounds.size.height;
        
        if((mCurrentLayerWidth > mWidth - 5 && mCurrentLayerWidth < mWidth + 5)){
            surface_ok = false ;
        }
    }
    this->configGL();
    
    if (surface_ok){
        
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &mGLSurfaceWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &mGLSurfaceHeight);
        glBindRenderbuffer(GL_RENDERBUFFER, mViewRenderbuffer);
        
        mPositionLoc = glGetAttribLocation(mGlProgram, "a_Position");
        mTexCoordLoc = glGetAttribLocation(mGlProgram, "a_texCoord");
        
        glVertexAttribPointer(mPositionLoc, 4, GL_FLOAT,GL_FALSE, VERTEX_STRIDE, mSquareVertices);
        glEnableVertexAttribArray(mPositionLoc);
        
        glVertexAttribPointer(mTexCoordLoc, 2, GL_FLOAT, GL_FALSE, VERTEX_STRIDE, &mSquareVertices[4]);
        glEnableVertexAttribArray(mTexCoordLoc);
        
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &mGLSurfaceWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &mGLSurfaceHeight);
        
        glViewport(0, 0, mGLSurfaceWidth, mGLSurfaceHeight);
        render(yuvdata);
    }else{
        LOGE("NativeGLRender error.");
        [m_lock unlock];
        return -1;
    }
    [m_lock unlock];
    return 0;
}

void GLRender::setTexture(GLuint texture)
{
    glBindTexture ( GL_TEXTURE_2D, texture);
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE );
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE );
}

void GLRender::render(PYUVData &yuvdata)
{
    const uint8_t *src_y = (uint8_t *)yuvdata->data[0];
    const uint8_t *src_u = (uint8_t *)yuvdata->data[1];
    const uint8_t *src_v = (uint8_t *)yuvdata->data[2];
    
    glBindRenderbuffer(GL_RENDERBUFFER, mViewRenderbuffer);
    [mContext  presentRenderbuffer:GL_RENDERBUFFER];
    
    glBindTexture ( GL_TEXTURE_2D, m_texturePlanarY);
    glTexImage2D ( GL_TEXTURE_2D, 0, GL_LUMINANCE, mWidth,   mHeight,   0, GL_LUMINANCE, GL_UNSIGNED_BYTE, src_y);
    
    glBindTexture( GL_TEXTURE_2D, m_texturePlanarU );
    glTexImage2D ( GL_TEXTURE_2D, 0, GL_LUMINANCE, mWidth/2, mHeight/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, src_u);
    
    glBindTexture ( GL_TEXTURE_2D,m_texturePlanarV );
    glTexImage2D ( GL_TEXTURE_2D, 0, GL_LUMINANCE, mWidth/2, mHeight/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, src_v);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

void GLRender::render( const void *data)
{
    const uint8_t *src_y = (const uint8_t *)data;
    const uint8_t *src_u = (const uint8_t *)data + mWidth * mHeight;
    const uint8_t *src_v = src_u + (mWidth / 2 * mHeight / 2);
    
    glBindTexture ( GL_TEXTURE_2D, m_texturePlanarY);
    glTexImage2D ( GL_TEXTURE_2D, 0, GL_LUMINANCE, mWidth,   mHeight,   0, GL_LUMINANCE, GL_UNSIGNED_BYTE, src_y);
    
    glBindTexture( GL_TEXTURE_2D, m_texturePlanarU );
    glTexImage2D ( GL_TEXTURE_2D, 0, GL_LUMINANCE, mWidth/2, mHeight/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, src_u);
    
    glBindTexture ( GL_TEXTURE_2D,m_texturePlanarV );
    glTexImage2D ( GL_TEXTURE_2D, 0, GL_LUMINANCE, mWidth/2, mHeight/2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, src_v);
}

void GLRender::configGL()
{
    if ((mSurface != NULL) && (!surface_ok)){
        if (mContext){
            mContext = nil;
        }
        
        memcpy(mSquareVertices,squareVertices,sizeof(squareVertices));
        if(!mContext){
            mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
            
            if (!mContext || ![EAGLContext setCurrentContext:mContext]) {
                return;
            }
        }
        
        this->releaseBuffers();
        this->setupBuffers();
        setupGraphics(mGLSurfaceWidth,mGLSurfaceHeight);
    }
}

int GLRender::digitalRegionZoom(int bootom_x , int bootom_y,  int top_x,  int top_y)
{
#define GET_SCALE(x)    (x/100.00)
#define CHECK_VALID(x)  (x<0||x>100)
    
    int stride = 6;
    if (CHECK_VALID(bootom_x) || CHECK_VALID(bootom_y) || CHECK_VALID(top_x) || CHECK_VALID(top_y)){
        return -1;
    }
    
    GLfloat zoom_textures[4][2]={
        static_cast<GLfloat>GET_SCALE(bootom_x),static_cast<GLfloat>(GET_SCALE(bootom_y)),
        static_cast<GLfloat>GET_SCALE( top_x  ),static_cast<GLfloat>GET_SCALE(bootom_y),
        static_cast<GLfloat>GET_SCALE( bootom_x  ), static_cast<GLfloat>GET_SCALE(top_y),
        static_cast<GLfloat>GET_SCALE(top_x), static_cast<GLfloat>GET_SCALE(top_y)
    };
    
    [m_lock lock];
    for(int i = 0; i < 4; i++){
        mSquareVertices[i*stride+4]=  zoom_textures[i][0];
        mSquareVertices[i*stride+4+1] = zoom_textures[i][1];
    }
    [m_lock unlock];
    return 0;
}

bool GLRender::setGLSurface(const int p_nWidth, const int p_nHeight, CAEAGLLayer  *layer)
{
    mWidth = p_nWidth;
    mHeight = p_nHeight;
    mSurface = layer;
    
    mCurrentLayerWidth = layer.bounds.size.width;
    mCurrentLayerHeight = layer.bounds.size.height;
    return true;
}

