//
//  CCAudioEncoder.h
//  001-Demo
//
//  Created by CC老师 on 2019/2/16.
//  Copyright © 2019年 CC老师. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@class CCAudioConfig;

/**AAC编码器代理*/
@protocol CCAudioEncoderDelegate <NSObject>
- (void)audioEncodeCallback:(NSData *)aacData;
@end

/**AAC硬编码器 (编码和回调均在异步队列执行)*/
@interface CCAudioEncoder : NSObject

/**编码器配置*/
@property (nonatomic, strong) CCAudioConfig *config;
@property (nonatomic, weak) id<CCAudioEncoderDelegate> delegate;

/**初始化传入编码器配置*/
- (instancetype)initWithConfig:(CCAudioConfig*)config;

/**编码*/
- (void)encodeAudioSamepleBuffer: (CMSampleBufferRef)sampleBuffer;
@end
