//
//  SceneModel.h
//  
//

#import <GLKit/GLKit.h>

@class AGLKVertexAttribArrayBuffer;
@class SceneMesh;


// 边界，注意min和max都是vector3
typedef struct
{
   GLKVector3 min;
   GLKVector3 max;
}
SceneAxisAllignedBoundingBox;


@interface SceneModel : NSObject

@property (copy, nonatomic, readonly) NSString
   *name;
@property (assign, nonatomic, readonly) 
   SceneAxisAllignedBoundingBox axisAlignedBoundingBox;


- (id)initWithName:(NSString *)aName
   mesh:(SceneMesh *)aMesh
   numberOfVertices:(GLsizei)aCount;
   
- (void)draw;

- (void)updateAlignedBoundingBoxForVertices:(float *)verts
   count:(unsigned int)aCount;

@end
