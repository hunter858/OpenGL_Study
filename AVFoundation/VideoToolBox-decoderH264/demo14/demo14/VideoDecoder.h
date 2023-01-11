//
//  VideoDecoder.h
//  demo14
//
//  Created by pengchao on 2022/6/24.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VideoDecoderDelegate <NSObject>
- (void)videoDecoderCallbackPixelBuffer:(UIImage *)pixeBuffer;
@end


@interface VideoDecoder : NSObject
@property (nonatomic, weak) id<VideoDecoderDelegate> delegate;

- (instancetype)initWithSps:(NSData *)sps pps:(NSData *)pps;

- (void)decoderWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
