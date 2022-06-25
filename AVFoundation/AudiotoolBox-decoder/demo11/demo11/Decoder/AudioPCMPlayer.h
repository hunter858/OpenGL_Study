//
//  AudioPCMPlayer.h
//  demo11
//
//  Created by pengchao on 2022/6/25.
//

#import <Foundation/Foundation.h>
#import "SystemCaptureManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AudioPCMPlayer : NSObject
- (instancetype)initWithConfig:(AudioConfig *)config;

- (void)playPCMData:(NSData *)data;

- (void)setupVoice:(Float32)gain;

- (void)dispose;
@end

NS_ASSUME_NONNULL_END
