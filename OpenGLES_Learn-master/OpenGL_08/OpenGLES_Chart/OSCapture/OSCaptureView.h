//
//  OSCaptureView.h
//  OpenGL_draw_cube
//
//  Created by xu jie on 16/8/2.
//  Copyright © 2016年 xujie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
typedef void (^Callback)(CGImageRef image);
@interface OSCaptureView : UIView
@property(nonatomic,strong)Callback callback;
-(void)setup:(Callback)callback;
@end
