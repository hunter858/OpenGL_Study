//
//  KYLPCMRecorder.m
//  yuvShowKYLDemo
//
//  Created by yulu kong on 2019/7/27.
//  Copyright © 2019 yulu kong. All rights reserved.
//

#import "KYLPCMRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

#define SAMPLES_PER_SECOND 8000


KYLPCMRecorder::KYLPCMRecorder(RecordAudioBufferCallback BuffCallback, void *param,int nSampleRate)
{
    m_bRecordStarted = 0;
    //===================================================
    dataFormat.mSampleRate=nSampleRate;
    dataFormat.mFormatID=kAudioFormatLinearPCM;
    dataFormat.mFormatFlags=kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    dataFormat.mBytesPerFrame=2;
    dataFormat.mBytesPerPacket=2;
    dataFormat.mFramesPerPacket=1;
    dataFormat.mChannelsPerFrame=1;
    dataFormat.mBitsPerChannel=16;
    dataFormat.mReserved=0;
    
    OSStatus status;
    status = AudioQueueNewInput(&dataFormat, BuffCallback, param, NULL, NULL, 0, &queue);
    if (status)
    {
        printf("can't establish new queue\n");
        return;
    }
    
    DeriveBufferSize(queue, dataFormat, 0.5, &bufferByteSize);
    
    // allocate those buffers and enqueue them
    int i;
    for(i = 0; i < NUM_BUFFERS; i++)
    {
        status = AudioQueueAllocateBuffer(queue, bufferByteSize, &buffers[i]);
        if (status)
        {
            printf("Error allocating buffer %d\n", i);
            return ;
        }
        
        status = AudioQueueEnqueueBuffer(queue, buffers[i], 0, NULL);
        if (status)
        {
            printf("Error enqueuing buffer %d\n", i);
            return ;
        }
    }
    
}

KYLPCMRecorder::~KYLPCMRecorder()
{
    StopRecord();
}

int KYLPCMRecorder::StopRecord()
{
    if(m_bRecordStarted == 0)
        return 1;
    
    AudioQueueFlush(queue);
    AudioQueueStop(queue, YES);
    
    for(int i = 0; i < NUM_BUFFERS; i++)
        AudioQueueFreeBuffer(queue, buffers[i]);
    
    AudioQueueDispose(queue, YES);
    m_bRecordStarted = 0;
    //    UInt32 audioCategory = kAudioSessionCategory_MediaPlayback;
    //    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);
    
    return 1;
}

int KYLPCMRecorder::StartRecord()
{
    if (m_bRecordStarted == 1) {
        return 1;
    }
    OSStatus status;
    status = AudioQueueStart(queue, NULL);
    if (status)
    {
        printf("Could not start Audio Queue status: %d\n", (int)status);
        return 0;
    }
    m_bRecordStarted = 1;
    //    UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
    //    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);
    return 1;
}

// Derive the Buffer Size. I punt with the max buffer size.
void KYLPCMRecorder::DeriveBufferSize (AudioQueueRef audioQueue, AudioStreamBasicDescription ASBDescription, Float64 seconds, UInt32 *outBufferSize)
{
    static const int maxBufferSize = 2048; // punting with 50k
    int maxPacketSize = ASBDescription.mBytesPerPacket;
    if (maxPacketSize == 0)
    {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty(audioQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &maxVBRPacketSize);
    }
    
    Float64 numBytesForTime = ASBDescription.mSampleRate * maxPacketSize * seconds;
    *outBufferSize =  (UInt32)((numBytesForTime < maxBufferSize) ? numBytesForTime : maxBufferSize);
}
