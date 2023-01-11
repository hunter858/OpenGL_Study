//
//  VideoEncoder.h
//  demo11
//
//  Created by pengchao on 2022/6/23.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "SystemCaptureManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol VideoEncoderDelegate <NSObject>
- (void)videoEncodeCallback:(NSData *)h264Data;
//Video-SPS&PPS数据编码回调
- (void)videoEncodeCallbacksps:(NSData *)sps pps:(NSData *)pps;
@end

@interface VideoEncoder : NSObject
@property (nonatomic, readonly) VideoConfig *videoConfig;

@property (nonatomic, weak) id<VideoEncoderDelegate> delegate;

- (instancetype)initWithConfig:(VideoConfig*)config;

- (void)encodeVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)encodeYUVData:(NSData *)YUVData;

- (void)start;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
