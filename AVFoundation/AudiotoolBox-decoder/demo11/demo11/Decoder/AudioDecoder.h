//
//  AudioDecoder.h
//  demo11
//
//  Created by pengchao on 2022/6/25.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SystemCaptureManager.h"
NS_ASSUME_NONNULL_BEGIN


/**AAC解码回调代理*/
@protocol AudioDecoderDelegate <NSObject>
- (void)audioDecodeCallback:(NSData *)pcmData;
@end

@interface AudioDecoder : NSObject

@property (nonatomic, strong) AudioConfig *config;
@property (nonatomic, weak) id<AudioDecoderDelegate> delegate;

- (instancetype)initWithConfig:(AudioConfig *)config;

- (void)decodeAudioAACData: (NSData *)aacData;

@end

NS_ASSUME_NONNULL_END
