//
//  AGLKFrustum.h
//  
//

#import <GLKit/GLKit.h>


typedef struct 
{  // 平截体定义
   GLKVector3 eyePosition;
   GLKVector3 xUnitVector;
   GLKVector3 yUnitVector;
   GLKVector3 zUnitVector;
   GLfloat aspectRatio;
   GLfloat nearDistance;
   GLfloat farDistance;
   
   // 平截体产生需要的属性
   GLfloat nearWidth;
   GLfloat nearHeight;
   GLfloat tangentOfHalfFieldOfView;
   GLfloat sphereFactorX;
   GLfloat sphereFactorY;
}
AGLKFrustum;


// 定义物体和平截体可能的关系
typedef enum
{
  AGLKFrustumIn,
  AGLKFrustumIntersects,
  AGLKFrustumOut,
} 
AGLKFrustumIntersectionType;


// 产生一个平截体
extern AGLKFrustum AGLKFrustumMakeFrustumWithParameters
(
   GLfloat fieldOfViewRad, 
   GLfloat aspectRatio, 
   GLfloat nearDistance, 
   GLfloat farDistance 
   );

// 设置平截体
extern void AGLKFrustumSetPerspective
(
   AGLKFrustum *frustumPtr, 
   GLfloat fieldOfViewRad, 
   GLfloat aspectRatio, 
   GLfloat nearDistance, 
   GLfloat farDistance 
   );

// eye位置和朝向
extern void AGLKFrustumSetPositionAndDirection
(
 AGLKFrustum *frustumPtr, 
 GLKVector3 position, 
 GLKVector3 lookAtPosition, 
 GLKVector3 up
 );

// 
extern void AGLKFrustumSetToMatchModelview
(
   AGLKFrustum *frustumPtr,
   GLKMatrix4 modelview
   ); 


// 判断平截体是否初始化
extern BOOL AGLKFrustumHasDimention
(
   const AGLKFrustum *frustumPtr
   );
      

// 判断点是否在平截体内
extern AGLKFrustumIntersectionType AGLKFrustumComparePoint
(
 const AGLKFrustum *frustumPtr, 
 GLKVector3 point
 );

// 判断球体是否在平截体内
extern AGLKFrustumIntersectionType AGLKFrustumCompareSphere
(
 const AGLKFrustum *frustumPtr, 
 GLKVector3 center, 
 GLfloat radius
 );


extern GLKMatrix4 AGLKFrustumMakePerspective
(
 const AGLKFrustum *frustumPtr
 );

extern GLKMatrix4 AGLKFrustumMakeModelview
(
 const AGLKFrustum *frustumPtr
 );
