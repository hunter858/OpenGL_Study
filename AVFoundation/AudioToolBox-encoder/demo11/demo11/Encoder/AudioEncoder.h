//
//  AudioHWEncoder.h
//  demo11
//
//  Created by pengchao on 2022/6/23.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SystemCaptureManager.h"


NS_ASSUME_NONNULL_BEGIN

@protocol AudioEncoderDelegate <NSObject>
- (void)audioEncodeCallback:(NSData *)aacData;
@end

@interface AudioEncoder : NSObject

@property (nonatomic, strong) AudioConfig *audioConfig;
@property (nonatomic, weak) id<AudioEncoderDelegate> delegate;

- (instancetype)initWithConfig:(AudioConfig*)config;

- (void)start;

- (void)stop;

- (void)encodeAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)encodeAudioData:(NSData *)pcmData;

- (NSData *)ADTSHeaderWithLength:(int)data_length;


@end

NS_ASSUME_NONNULL_END
