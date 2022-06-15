//
//  RenderView.h
//  OpenGL
//
//  Created by pengchao on 2022/1/7.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RenderView : UIView

- (void)sendPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (void)display;
@end

NS_ASSUME_NONNULL_END
