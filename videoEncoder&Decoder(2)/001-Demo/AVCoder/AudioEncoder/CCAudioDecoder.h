//
//  CCAudioDecoder.h
//  001-Demo
//
//  Created by CC老师 on 2019/2/16.
//  Copyright © 2019年 CC老师. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@class CCAudioConfig;

/**AAC解码回调代理*/
@protocol CCAudioDecoderDelegate <NSObject>
- (void)audioDecodeCallback:(NSData *)pcmData;
@end

@interface CCAudioDecoder : NSObject
@property (nonatomic, strong) CCAudioConfig *config;
@property (nonatomic, weak) id<CCAudioDecoderDelegate> delegate;

//初始化 传入解码配置
- (instancetype)initWithConfig:(CCAudioConfig *)config;

/**解码aac*/
- (void)decodeAudioAACData: (NSData *)aacData;
@end
