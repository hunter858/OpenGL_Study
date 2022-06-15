//
//  CCVideoDecoder.h
//  001-Demo
//
//  Created by CC老师 on 2019/2/16.
//  Copyright © 2019年 CC老师. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CCAVConfig.h"

/**h264解码回调代理*/
@protocol CCVideoDecoderDelegate <NSObject>
//解码后H264数据回调
- (void)videoDecodeCallback:(CVPixelBufferRef)imageBuffer;
@end

@interface CCVideoDecoder : NSObject
@property (nonatomic, strong) CCVideoConfig *config;
@property (nonatomic, weak) id<CCVideoDecoderDelegate> delegate;

/**初始化解码器**/
- (instancetype)initWithConfig:(CCVideoConfig*)config;

/**解码h264数据*/
- (void)decodeNaluData:(NSData *)frame;
@end
