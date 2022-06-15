//
//  SceneCar.m
//
//

#import "SceneCar.h"


@interface SceneCar ()

@property (strong, nonatomic, readwrite) SceneModel
*model;
@property (assign, nonatomic, readwrite) GLKVector3
position;
@property (assign, nonatomic, readwrite) GLKVector3
nextPosition;
@property (assign, nonatomic, readwrite) GLKVector3
velocity;
@property (assign, nonatomic, readwrite) GLfloat
yawRadians;
@property (assign, nonatomic, readwrite) GLfloat
targetYawRadians;
@property (assign, nonatomic, readwrite) GLKVector4
color;
@property (assign, nonatomic, readwrite) GLfloat
radius;

@end


@implementation SceneCar

static long bounceCount;

@synthesize model;
@synthesize position;
@synthesize velocity;
@synthesize yawRadians;
@synthesize targetYawRadians;
@synthesize color;
@synthesize nextPosition;
@synthesize radius;


+ (void)initialize {
    bounceCount = 0;
}

+ (long)getBounceCount {
    return bounceCount;
}

- (id)init
{
    NSAssert(0, @"Invalid initializer");
    
    self = nil;
    
    return self;
}

// Designated initializer
- (id)initWithModel:(SceneModel *)aModel
           position:(GLKVector3)aPosition
           velocity:(GLKVector3)aVelocity
              color:(GLKVector4)aColor;
{
    if(nil != (self = [super init]))
    {
        self.position = aPosition;
        self.color = aColor;
        self.velocity = aVelocity;
        self.model = aModel;
        
        SceneAxisAllignedBoundingBox axisAlignedBoundingBox =
        self.model.axisAlignedBoundingBox;
        
        // Half the widest diameter is radius
        self.radius = 0.5f * MAX(axisAlignedBoundingBox.max.x -
                                 axisAlignedBoundingBox.min.x,
                                 axisAlignedBoundingBox.max.z -
                                 axisAlignedBoundingBox.min.z);
    }
    
    return self;
}


//检测car和墙的碰撞
- (void)bounceOffWallsWithBoundingBox:(SceneAxisAllignedBoundingBox)rinkBoundingBox
{
    if((rinkBoundingBox.min.x + self.radius) > self.nextPosition.x)
    {
        //下一个点超过了x最小的边界
        self.nextPosition = GLKVector3Make((rinkBoundingBox.min.x + self.radius),
                                           self.nextPosition.y, self.nextPosition.z);
        //撞墙后x方向 相反
        self.velocity = GLKVector3Make(-self.velocity.x, self.velocity.y, self.velocity.z);
    }
    else if((rinkBoundingBox.max.x - self.radius) < self.nextPosition.x)
    {
        //下一个点超过了x最大的边界
        self.nextPosition = GLKVector3Make((rinkBoundingBox.max.x - self.radius), self.nextPosition.y, self.nextPosition.z);
        self.velocity = GLKVector3Make(-self.velocity.x,
                                       self.velocity.y, self.velocity.z);
    }
    
    //z的边界判断
    if((rinkBoundingBox.min.z + self.radius) > self.nextPosition.z)
    {
        self.nextPosition = GLKVector3Make(self.nextPosition.x,
                                           self.nextPosition.y,
                                           (rinkBoundingBox.min.z + self.radius));
        self.velocity = GLKVector3Make(self.velocity.x,
                                       self.velocity.y, -self.velocity.z);
    }
    else if((rinkBoundingBox.max.z - self.radius) <
            self.nextPosition.z)
    {
        self.nextPosition = GLKVector3Make(self.nextPosition.x,
                                           self.nextPosition.y,
                                           (rinkBoundingBox.max.z - self.radius));
        self.velocity = GLKVector3Make(self.velocity.x,
                                       self.velocity.y, -self.velocity.z);
    }
}



//检测cars之间的碰撞
- (void)bounceOffCars:(NSArray *)cars elapsedTime:(NSTimeInterval)elapsedTimeSeconds
{
    for(SceneCar *currentCar in cars)
    {
        if(currentCar != self)
        {
            float distance = GLKVector3Distance(self.nextPosition, currentCar.nextPosition);
            
            if((2.0f * self.radius) > distance)
            {
                ++bounceCount;
                GLKVector3 ownVelocity = self.velocity;
                GLKVector3 otherVelocity = currentCar.velocity;
                GLKVector3 directionToOtherCar = GLKVector3Subtract(currentCar.position, self.position);
                
                directionToOtherCar = GLKVector3Normalize(directionToOtherCar);
                GLKVector3 negDirectionToOtherCar = GLKVector3Negate(directionToOtherCar);
                
                GLKVector3 tanOwnVelocity = GLKVector3MultiplyScalar(negDirectionToOtherCar, GLKVector3DotProduct(ownVelocity, negDirectionToOtherCar));
                GLKVector3 tanOtherVelocity = GLKVector3MultiplyScalar(directionToOtherCar, GLKVector3DotProduct(otherVelocity, directionToOtherCar));
                GLKVector3 travelDistance;
                //更新自己的速度
                self.velocity = GLKVector3Subtract(ownVelocity, tanOwnVelocity);
                travelDistance = GLKVector3MultiplyScalar(self.velocity, elapsedTimeSeconds);
                self.nextPosition = GLKVector3Add(self.position, travelDistance);
//                NSLog(@"after bounce %f %f %f", travelDistance.x, travelDistance.y, travelDistance.z);
                
                //更新其他car的速度
                currentCar.velocity = GLKVector3Subtract(otherVelocity, tanOtherVelocity);
                travelDistance = GLKVector3MultiplyScalar(currentCar.velocity, elapsedTimeSeconds);
                currentCar.nextPosition = GLKVector3Add(currentCar.position, travelDistance);
            }
        }
    }
}


- (void)spinTowardDirectionOfMotion:(NSTimeInterval)elapsed
{
    self.yawRadians = SceneScalarSlowLowPassFilter(elapsed,
                                                   self.targetYawRadians,
                                                   self.yawRadians);
    if (self.mCarId > 0) {
        NSLog(@"yawRadians %f", GLKMathRadiansToDegrees(self.yawRadians));
    }
}


// 更新car的位置、偏航角和速度
// 模拟与墙和其他car的碰撞
- (void)updateWithController:
(id <SceneCarControllerProtocol>)controller;
{
    //0.01秒和0.5秒之间
    NSTimeInterval   elapsedTimeSeconds = MIN(MAX([controller timeSinceLastUpdate], 0.01f), 0.5f);
    //    NSLog(@"sinceLastUpdate %f  => %f", [controller timeSinceLastUpdate], elapsedTimeSeconds);
    
    
    GLKVector3 travelDistance = GLKVector3MultiplyScalar(self.velocity, elapsedTimeSeconds);
    
    self.nextPosition = GLKVector3Add(self.position, travelDistance);
    
    SceneAxisAllignedBoundingBox rinkBoundingBox = [controller rinkBoundingBox];
    
    [self bounceOffCars:[controller cars] elapsedTime:elapsedTimeSeconds];
    [self bounceOffWallsWithBoundingBox:rinkBoundingBox];
    
    if(0.1 > GLKVector3Length(self.velocity))
    {  // 速度太小，方向可能是个死角，随机换一个方向
        self.velocity = GLKVector3Make((random() / (0.5f * RAND_MAX)) - 1.0f,
                                       0.0f,
                                       (random() / (0.5f * RAND_MAX)) - 1.0f);
    }
    else if(4 > GLKVector3Length(self.velocity))
    {  // 缓慢加速
        self.velocity = GLKVector3MultiplyScalar(self.velocity, 1.01f);
    }
    

    //car的方向和标准方向的余弦值
    float dotProduct = GLKVector3DotProduct(GLKVector3Normalize(self.velocity), GLKVector3Make(0.0, 0, -1.0));
    
    if(0.0 > self.velocity.x)
    {  //偏航角为正
        self.targetYawRadians = acosf(dotProduct);
    }
    else
    {  //偏航角为负
        self.targetYawRadians = -acosf(dotProduct);
    }
//    NSLog(@"\nvelocity %f %f %f\n %f \n", self.position.x, self.position.y, self.position.z, GLKMathRadiansToDegrees(self.targetYawRadians));
    
    [self spinTowardDirectionOfMotion:elapsedTimeSeconds];
    
    self.position = self.nextPosition;
}

//绘制
- (void)drawWithBaseEffect:(GLKBaseEffect *)anEffect;
{
    // 缓存
    GLKMatrix4  savedModelviewMatrix = anEffect.transform.modelviewMatrix;
    GLKVector4  savedDiffuseColor = anEffect.material.diffuseColor;
    GLKVector4  savedAmbientColor = anEffect.material.ambientColor;
    
    // Translate to the model's position
    anEffect.transform.modelviewMatrix =
    GLKMatrix4Translate(savedModelviewMatrix,
                        position.x, position.y, position.z);
    
    // 绕Y轴旋转偏航角大小
    anEffect.transform.modelviewMatrix =
    GLKMatrix4Rotate(anEffect.transform.modelviewMatrix,
                     self.yawRadians,
                     0.0, 1.0, 0.0);
    
    //设置材质
    anEffect.material.diffuseColor = self.color;
    anEffect.material.ambientColor = self.color;
    [anEffect prepareToDraw];
    [model draw];
    
    
    anEffect.transform.modelviewMatrix = savedModelviewMatrix;
    anEffect.material.diffuseColor = savedDiffuseColor;
    anEffect.material.ambientColor = savedAmbientColor;
}

- (void)onSpeedChange:(BOOL)slow {
    if (slow) {
        self.velocity = GLKVector3MultiplyScalar(self.velocity, 0.9);
    }
    else {
        self.velocity = GLKVector3MultiplyScalar(self.velocity, 1.1);
    }
}

@end



GLfloat SceneScalarFastLowPassFilter(NSTimeInterval elapsed,
                                     GLfloat target,
                                     GLfloat current)
{
//    NSLog(@"target - current %f", target - current);
    return current + (50.0 * elapsed * (target - current));
}


GLfloat SceneScalarSlowLowPassFilter(NSTimeInterval elapsed,
                                     GLfloat target,
                                     GLfloat current)
{
    return current + (4.0 * elapsed * (target - current));
}


GLKVector3 SceneVector3FastLowPassFilter(NSTimeInterval elapsed,
                                         GLKVector3 target,
                                         GLKVector3 current)
{
    return GLKVector3Make(SceneScalarFastLowPassFilter(elapsed, target.x, current.x),
                          SceneScalarFastLowPassFilter(elapsed, target.y, current.y),
                          SceneScalarFastLowPassFilter(elapsed, target.z, current.z));
}


GLKVector3 SceneVector3SlowLowPassFilter(NSTimeInterval elapsed,
                                         GLKVector3 target,
                                         GLKVector3 current)
{
    return GLKVector3Make(SceneScalarSlowLowPassFilter(elapsed, target.x, current.x),
                          SceneScalarSlowLowPassFilter(elapsed, target.y, current.y),
                          SceneScalarSlowLowPassFilter(elapsed, target.z, current.z));
}
