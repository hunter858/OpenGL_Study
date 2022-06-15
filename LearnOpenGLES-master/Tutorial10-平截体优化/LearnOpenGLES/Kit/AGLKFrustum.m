//
//  AGLKFrustum.m
//
//

#import "AGLKFrustum.h"
#include <GLKit/GLKit.h>

// 调用此函数后
// 投影矩阵通过AGLKFrustumMakePerspective()返回
AGLKFrustum AGLKFrustumMakeFrustumWithParameters
(
 GLfloat fieldOfViewRad,
 GLfloat aspectRatio,
 GLfloat nearDistance,
 GLfloat farDistance)
{
    AGLKFrustum frustum;
    
    AGLKFrustumSetPerspective(
                              &frustum,
                              fieldOfViewRad,
                              aspectRatio,
                              nearDistance,
                              farDistance);
    
    return frustum;
}



extern void AGLKFrustumSetPerspective
(
 AGLKFrustum *frustumPtr,
 GLfloat fieldOfViewRad,
 GLfloat aspectRatio,
 GLfloat nearDistance,
 GLfloat farDistance
 )
{
    NSCAssert(NULL != frustumPtr,
              @"Invalid frustumPtr parameter");
    NSCAssert(0.0f < fieldOfViewRad && M_PI > fieldOfViewRad,
              @"Invalid fieldOfViewRad");
    NSCAssert(0.0f < aspectRatio, @"Invalid aspectRatio");
    NSCAssert(0.0f < nearDistance, @"Invalid nearDistance");
    NSCAssert(nearDistance < farDistance, @"Invalid farDistance");
    
    const GLfloat halfFieldOfViewRad = 0.5f * fieldOfViewRad;
    
    frustumPtr->aspectRatio = aspectRatio;
    frustumPtr->nearDistance = nearDistance;
    frustumPtr->farDistance = farDistance;
    
    //正弦值
    frustumPtr->tangentOfHalfFieldOfView = tanf(halfFieldOfViewRad);
    frustumPtr->nearHeight = nearDistance * frustumPtr->tangentOfHalfFieldOfView;
    frustumPtr->nearWidth = frustumPtr->nearHeight * aspectRatio;
    
    // 计算球体放大因子
    // 原代码这里的部分有问题，用170°进行测试，可以发现这一行代码有bug，地球还未完全消失时候，物体就消失了。
    //    frustumPtr->sphereFactorY = 1.0f/cosf(frustumPtr->tangentOfHalfFieldOfView);
    frustumPtr->sphereFactorY = 1.0f/cosf(halfFieldOfViewRad);
    const GLfloat angleX = atanf(frustumPtr->tangentOfHalfFieldOfView * aspectRatio);
    frustumPtr->sphereFactorX = 1.0f/cosf(angleX);
}


// 长度的平方，不是用sqrt()
static __inline__ GLfloat AGLKVector3LengthSquared(
                                                   GLKVector3 vector
                                                   )
{
    return (
            vector.v[0] * vector.v[0] +
            vector.v[1] * vector.v[1] +
            vector.v[2] * vector.v[2]
            );
}


void AGLKFrustumSetPositionAndDirection
(
 AGLKFrustum *frustumPtr,
 GLKVector3 eyePosition,
 GLKVector3 lookAtPosition,
 GLKVector3 upVector)
{
    NSCAssert(NULL != frustumPtr,
              @"Invalid frustumPtr parameter");
    
    frustumPtr->eyePosition = eyePosition;
    
    // Z轴 从 eye position 到 look at position
    const GLKVector3 lookAtVector =
    GLKVector3Subtract(eyePosition, lookAtPosition);
    NSCAssert(0.0f < AGLKVector3LengthSquared(lookAtVector),
              @"Invalid eyeLookPosition parameter");
    frustumPtr->zUnitVector = GLKVector3Normalize(lookAtVector);
    
    // X轴 z轴和up向量的叉积
    frustumPtr->xUnitVector = GLKVector3CrossProduct(
                                                     GLKVector3Normalize(upVector),
                                                     frustumPtr->zUnitVector);
    
    // Y轴 x轴和z轴的叉积
    frustumPtr->yUnitVector = GLKVector3CrossProduct(
                                                     frustumPtr->zUnitVector,
                                                     frustumPtr->xUnitVector);
}


void AGLKFrustumSetToMatchModelview
(
 AGLKFrustum *frustumPtr,
 GLKMatrix4 modelview
 )
{
    frustumPtr->xUnitVector = GLKVector3Make(
                                             modelview.m00, modelview.m10, modelview.m20);
    frustumPtr->yUnitVector = GLKVector3Make(
                                             modelview.m01, modelview.m11, modelview.m21);
    frustumPtr->zUnitVector = GLKVector3Make(
                                             modelview.m02, modelview.m12, modelview.m22);
}


BOOL AGLKFrustumHasDimention
(const AGLKFrustum *frustumPtr)
{
    NSCAssert(NULL != frustumPtr, @"Invalid frustumPtr parameter");
    
    return (frustumPtr->nearDistance < frustumPtr->farDistance) &&
    (0.0f < frustumPtr->tangentOfHalfFieldOfView) &&
    (0.0f < fabs(frustumPtr->aspectRatio));
}


AGLKFrustumIntersectionType AGLKFrustumComparePoint
(
 const AGLKFrustum *frustumPtr, GLKVector3 point)
{
    NSCAssert(AGLKFrustumHasDimention(frustumPtr),
              @"Invalid frustumPtr parameter");
    
    AGLKFrustumIntersectionType result = AGLKFrustumIn;
    
    // eye到point的向量
    const GLKVector3 eyeToPoint = GLKVector3Subtract(frustumPtr->eyePosition, point);
    
    // z轴分量
    const GLfloat pointZComponent = GLKVector3DotProduct(eyeToPoint, frustumPtr->zUnitVector);
    
    if(pointZComponent > frustumPtr->farDistance || pointZComponent < frustumPtr->nearDistance)
    {
        result = AGLKFrustumOut;
    }
    else
    {
        // y轴分量
        const GLfloat pointYComponent =
        GLKVector3DotProduct(eyeToPoint,
                             frustumPtr->yUnitVector);
        const GLfloat frustumHeightAtZ = pointZComponent * frustumPtr->tangentOfHalfFieldOfView;
        
        if(pointYComponent > frustumHeightAtZ || pointYComponent < -frustumHeightAtZ)
        {
            result = AGLKFrustumOut;
        }
        else
        {  //X轴分量
            const GLfloat pointXComponent =
            GLKVector3DotProduct(eyeToPoint,
                                 frustumPtr->xUnitVector);
            const GLfloat frustumWidthAtZ = frustumHeightAtZ *
            frustumPtr->aspectRatio;
            
            if(pointXComponent > frustumWidthAtZ ||
               pointXComponent < -frustumWidthAtZ)
            {
                result = AGLKFrustumOut;
            }
        }
    }
    
    return result;
}


AGLKFrustumIntersectionType AGLKFrustumCompareSphere
(
 const AGLKFrustum *frustumPtr,
 GLKVector3 center, GLfloat radius)
{
    NSCAssert(AGLKFrustumHasDimention(frustumPtr),
              @"Invalid frustumPtr parameter");
    
    AGLKFrustumIntersectionType result = AGLKFrustumIn;
    
    const GLKVector3 eyeToCenter =
    GLKVector3Subtract(
                       frustumPtr->eyePosition, center);
    
    const GLfloat centerZComponent =
    GLKVector3DotProduct(eyeToCenter,
                         frustumPtr->zUnitVector);
    if (centerZComponent > (frustumPtr->farDistance + radius) ||
        centerZComponent < (frustumPtr->nearDistance - radius)) {
        result = AGLKFrustumOut;
    }
    else if(centerZComponent > (frustumPtr->farDistance - radius) ||
            centerZComponent < (frustumPtr->nearDistance + radius))
    {  // the sphere intersects the frustum
        result = AGLKFrustumIntersects;
    }
    
    if(AGLKFrustumOut != result)
    {
        const GLfloat centerYComponent =
        GLKVector3DotProduct(eyeToCenter,
                             frustumPtr->yUnitVector);
        const GLfloat yDistance =
        frustumPtr->sphereFactorY * radius;
        const GLfloat frustumHalfHeightAtZ =
        centerZComponent * frustumPtr->tangentOfHalfFieldOfView;
        
        if(centerYComponent > (frustumHalfHeightAtZ + yDistance) ||
           centerYComponent < (-frustumHalfHeightAtZ - yDistance))
        {
            result = AGLKFrustumOut;
        }
        else if(centerYComponent > (frustumHalfHeightAtZ - yDistance) ||
                centerYComponent < (-frustumHalfHeightAtZ + yDistance))
        {
            result = AGLKFrustumIntersects;
        }
        
        if(AGLKFrustumOut != result)
        {
            const GLfloat centerXComponent =
            GLKVector3DotProduct(eyeToCenter,
                                 frustumPtr->xUnitVector);
            const GLfloat xDistance =
            frustumPtr->sphereFactorX * radius;
            const GLfloat frustumHalfWidthAtZ =
            frustumHalfHeightAtZ * frustumPtr->aspectRatio;
            
            if(centerXComponent > (frustumHalfWidthAtZ + xDistance) ||
               centerXComponent < (-frustumHalfWidthAtZ - xDistance))
            {
                result = AGLKFrustumOut;
            }
            else if(centerXComponent > (frustumHalfWidthAtZ - xDistance) ||
                    centerXComponent < (-frustumHalfWidthAtZ + xDistance))
            {
                result = AGLKFrustumIntersects;
            }
        }
    }
    
    return result;
}



extern GLKMatrix4 AGLKFrustumMakePerspective
(
 const AGLKFrustum *frustumPtr
 )
{
    NSCAssert(AGLKFrustumHasDimention(frustumPtr),
              @"Invalid frustumPtr parameter");
    
    const GLfloat cotan =
    1.0f / frustumPtr->tangentOfHalfFieldOfView;
    const GLfloat nearZ = frustumPtr->nearDistance;
    const GLfloat farZ = frustumPtr->farDistance;
    
    GLKMatrix4 m = {
        cotan / frustumPtr->aspectRatio, 0.0f, 0.0f, 0.0f,
        0.0f, cotan, 0.0f, 0.0f,
        0.0f, 0.0f, (farZ + nearZ) / (nearZ - farZ), -1.0f,
        0.0f, 0.0f, (2.0f * farZ * nearZ) / (nearZ - farZ), 0.0f
    };
    
    return m;
}

GLKMatrix4 AGLKFrustumMakeModelview
(
 const AGLKFrustum *frustumPtr) 
{
    NSCAssert(AGLKFrustumHasDimention(frustumPtr), 
              @"Invalid frustumPtr parameter");
    
    const GLKVector3 eyePosition = frustumPtr->eyePosition;
    const GLKVector3 xNormal = frustumPtr->xUnitVector;
    const GLKVector3 yNormal = frustumPtr->yUnitVector;
    const GLKVector3 zNormal = frustumPtr->zUnitVector;
    const GLfloat xTranslation = GLKVector3DotProduct(
                                                      xNormal, eyePosition);
    const GLfloat yTranslation = GLKVector3DotProduct(
                                                      yNormal, eyePosition);
    const GLfloat zTranslation = GLKVector3DotProduct(
                                                      zNormal, eyePosition);
    
    GLKMatrix4 m = {
        // X Axis     Y Axis     Z Axis 
        xNormal.x, yNormal.x, zNormal.x,             0.0f,
        xNormal.y, yNormal.y, zNormal.y,             0.0f,
        xNormal.z, yNormal.z, zNormal.z,             0.0f,
        
        // Axis Origin
        -xTranslation, -yTranslation, -zTranslation, 1.0f
    };
    
    return m;
}
