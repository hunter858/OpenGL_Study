//
//  KYLGLKController.h
//  yuvShowKYLDemo
//
//  Created by yulu kong on 2019/7/27.
//  Copyright © 2019 yulu kong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KYLGLKController : GLKViewController
- (void)writeYUVFrame:(Byte *)pYUV Len:(NSInteger)length width:(NSInteger)width height:(NSInteger)height;
@end

NS_ASSUME_NONNULL_END
