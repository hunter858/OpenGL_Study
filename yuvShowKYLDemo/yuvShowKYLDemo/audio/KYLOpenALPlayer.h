//
//  KYLOpenALPlayer.h
//  yuvShowKYLDemo
//
//  Created by yulu kong on 2019/7/27.
//  Copyright © 2019 yulu kong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/ExtendedAudioFile.h>

NS_ASSUME_NONNULL_BEGIN

@interface KYLOpenALPlayer : NSObject
- (BOOL) startAudio:(int) nsampleRate;
- (BOOL) stopAudio;
- (BOOL) addOneFrameAudioData:(NSData *) data;


+ (BOOL)initAudioSessionForPlayer;
+ (BOOL)initAudioSessionForRecord;
+ (BOOL)exitAudioSession;

- (void)initOpenAL:(int)format :(int)sampleRate;
- (void)openAudioFromQueue:(NSData *)data;
- (void)stopSound;
- (void)cleanUpOpenAL;
@end

NS_ASSUME_NONNULL_END
