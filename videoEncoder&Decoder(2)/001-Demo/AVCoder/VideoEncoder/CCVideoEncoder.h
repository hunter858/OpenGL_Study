//
//  CCVideoEncoder.h
//  001-Demo
//
//  Created by CC老师 on 2019/2/16.
//  Copyright © 2019年 CC老师. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CCAVConfig.h"

/**h264编码回调代理*/
@protocol CCVideoEncoderDelegate <NSObject>
//Video-H264数据编码完成回调
- (void)videoEncodeCallback:(NSData *)h264Data;
//Video-SPS&PPS数据编码回调
- (void)videoEncodeCallbacksps:(NSData *)sps pps:(NSData *)pps;
@end

/**h264硬编码器 (编码和回调均在异步队列执行)*/
@interface CCVideoEncoder : NSObject
@property (nonatomic, strong) CCVideoConfig *config;
@property (nonatomic, weak) id<CCVideoEncoderDelegate> delegate;

- (instancetype)initWithConfig:(CCVideoConfig*)config;
/**编码*/
-(void)encodeVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
