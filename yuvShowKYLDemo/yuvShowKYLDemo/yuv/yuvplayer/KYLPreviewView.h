//
//  KYLPreviewView.h
//  yuvShowKYLDemo
//
//  Created by yulu kong on 2019/7/27.
//  Copyright © 2019 yulu kong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KYLPreviewView : UIView


/**
 Whether full the screen
 */
@property (nonatomic, assign, getter=isFullScreen) BOOL fullScreen;

/**
 display
 */
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
