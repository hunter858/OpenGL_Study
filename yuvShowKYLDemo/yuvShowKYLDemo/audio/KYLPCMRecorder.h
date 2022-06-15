//
//  KYLPCMRecorder.h
//  yuvShowKYLDemo
//
//  Created by yulu kong on 2019/7/27.
//  Copyright © 2019 yulu kong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioFile.h>
#include <AudioToolbox/AudioQueue.h>
#include <AudioToolbox/AudioServices.h>

NS_ASSUME_NONNULL_BEGIN


#define NUM_BUFFERS 3


typedef  void (*RecordAudioBufferCallback)(void *aqData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, const AudioTimeStamp *inStartTime, UInt32 inNumPackets, const AudioStreamPacketDescription *inPacketDesc);

class KYLPCMRecorder
{
public:
    KYLPCMRecorder(RecordAudioBufferCallback BuffCallback, void *param, int nSampleRate= 8000);
    ~KYLPCMRecorder();
    int StartRecord();
    
private:
    int StopRecord();
    void DeriveBufferSize (AudioQueueRef audioQueue, AudioStreamBasicDescription ASBDescription, Float64 seconds, UInt32 *outBufferSize);
    
private:
    AudioStreamBasicDescription dataFormat;
    AudioQueueRef               queue;
    AudioQueueBufferRef         buffers[NUM_BUFFERS];
    UInt32                      bufferByteSize;
    int m_bRecordStarted;
};


NS_ASSUME_NONNULL_END
