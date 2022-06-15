//
//  KYLOpenALPlayer.m
//  yuvShowKYLDemo
//
//  Created by yulu kong on 2019/7/27.
//  Copyright © 2019 yulu kong. All rights reserved.
//

#import "KYLOpenALPlayer.h"
@interface KYLOpenALPlayer () {
    ALCcontext *mContext;
    ALCdevice *mDevice;
    ALuint outSourceID;
    
    NSMutableDictionary* soundDictionary;
    NSMutableArray* bufferStorageArray;
    
    ALuint buff;
    NSTimer* updateBufferTimer;
    
    ALenum audioFormat;
    int sampleRate;
}
@property (nonatomic) ALenum audioFormat;
@property (nonatomic) ALCcontext *mContext;
@property (nonatomic) ALCdevice *mDevice;
@property (nonatomic,strong)NSMutableDictionary* soundDictionary;
@property (nonatomic,strong)NSMutableArray* bufferStorageArray;
@property (nonatomic, assign) int sampleRate;

@end

@implementation KYLOpenALPlayer

+ (KYLOpenALPlayer *)sharedInstanced
{
    static KYLOpenALPlayer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[KYLOpenALPlayer alloc] init];
        
    });
    return sharedInstance;
}




- (BOOL) startAudio:(int) nsampleRate
{
    self.sampleRate = nsampleRate;
    //[self initAudioSession];
    [self initOpenAL:AL_FORMAT_MONO16 :nsampleRate];
    return YES;
}

- (BOOL) stopAudio
{
    [self stopSound];
    [self cleanUpOpenAL];
    //[self exitAudioSession];
    return YES;
}

- (BOOL) addOneFrameAudioData:(NSData *) data
{
    [self openAudioFromQueue:data];
    return YES;
}

#pragma mark - openal function
-(void)initOpenAL:(int)format :(int)sampleRate_
{
    //processed =0;
    //queued =0;
    
    audioFormat = format;
    sampleRate = sampleRate_;
    
    //init the device and context
    mDevice=alcOpenDevice(NULL);
    if (mDevice) {
        mContext=alcCreateContext(mDevice, NULL);
        alcMakeContextCurrent(mContext);
    }
    alGenSources(1, &outSourceID);
    alSpeedOfSound(1.0);
    alDopplerVelocity(1.0);
    alDopplerFactor(1.0);
    alSourcef(outSourceID, AL_PITCH, 1.0f);
    alSourcef(outSourceID, AL_GAIN, 1.0f);
    alSourcei(outSourceID, AL_LOOPING, AL_FALSE);
    alSourcef(outSourceID, AL_SOURCE_TYPE, AL_STREAMING);
    
    //alSourcef(outSourceID, AL_BUFFERS_QUEUED, 29);
}


- (BOOL) updateQueueBuffer
{
    ALint stateVaue;
    int processed, queued;
    
    
    alGetSourcei(outSourceID, AL_SOURCE_STATE, &stateVaue);
    
    if (stateVaue == AL_STOPPED /*||
                                 stateVaue == AL_PAUSED ||
                                 stateVaue == AL_INITIAL*/)
    {
        //[self playSound];
        return NO;
    }
    
    alGetSourcei(outSourceID, AL_BUFFERS_PROCESSED, &processed);
    alGetSourcei(outSourceID, AL_BUFFERS_QUEUED, &queued);
    
    while(processed--)
    {
        alSourceUnqueueBuffers(outSourceID, 1, &buff);
        alDeleteBuffers(1, &buff);
    }
    
    return YES;
}

- (void)openAudioFromQueue:(NSData *)data
{
    
    @autoreleasepool{
        NSCondition* ticketCondition= [[NSCondition alloc] init];
        [ticketCondition lock];
        [self updateQueueBuffer];
        ALuint bufferID = 0;
        alGenBuffers(1, &bufferID);
        alBufferData(bufferID, self.audioFormat, [data bytes], (int)[data length], self.sampleRate);
        alSourceQueueBuffers(outSourceID, 1, &bufferID);
        ALint stateVaue;
        alGetSourcei(outSourceID, AL_SOURCE_STATE, &stateVaue);
        if (stateVaue != AL_PLAYING)
        {
            alSourcePlay(outSourceID);
        }
        [ticketCondition unlock];
    }
}

#pragma mark - play/stop/clean function
-(void)playSound
{
    //alSourcePlay(outSourceID);
}

-(void)stopSound
{
    alSourceStop(outSourceID);
}

-(void)cleanUpOpenAL
{
    int processed = 0;
    alGetSourcei(outSourceID, AL_BUFFERS_PROCESSED, &processed);
    
    while(processed--) {
        alSourceUnqueueBuffers(outSourceID, 1, &buff);
        alDeleteBuffers(1, &buff);
    }

    alDeleteSources(1, &outSourceID);
    alcMakeContextCurrent(NULL);

    alcDestroyContext(mContext);

    alcCloseDevice(mDevice);
}

#pragma mark - 供参考  play/stop/clean

// the main method: grab the sound ID from the library
// and start the source playing
- (void)playSound:(NSString*)soundKey
{
    NSNumber* numVal = [soundDictionary objectForKey:soundKey];
    if (numVal == nil)
        return;
    
    unsigned int sourceID = [numVal unsignedIntValue];
    alSourcePlay(sourceID);
}

- (void)stopSound:(NSString*)soundKey
{
    NSNumber* numVal = [soundDictionary objectForKey:soundKey];
    if (numVal == nil)
        return;
    unsigned int sourceID = [numVal unsignedIntValue];
    alSourceStop(sourceID);
}


-(void)cleanUpOpenAL:(id)sender
{
    // delete the sources
    for (NSNumber* sourceNumber in [soundDictionary allValues])
    {
        unsigned int sourceID = [sourceNumber unsignedIntValue];
        alDeleteSources(1, &sourceID);
    }
    
    [soundDictionary removeAllObjects];
    // delete the buffers
    for (NSNumber* bufferNumber in bufferStorageArray)
    {
        unsigned int bufferID = [bufferNumber unsignedIntValue];
        alDeleteBuffers(1, &bufferID);
    }
    [bufferStorageArray removeAllObjects];
    
    // destroy the context
    alcDestroyContext(mContext);
    // close the device
    alcCloseDevice(mDevice);
}


#pragma mark - unused function
////////////////////////////////////////////
//crespo study openal function,need import audiotoolbox framework and 2 header file
////////////////////////////////////////////


// open the audio file
// returns a big audio ID struct
-(AudioFileID)openAudioFile:(NSString*)filePath
{
    AudioFileID outAFID;
    // use the NSURl instead of a cfurlref cuz it is easier
    NSURL * afUrl = [NSURL fileURLWithPath:filePath];
    // do some platform specific stuff..
#if TARGET_OS_IPHONE
    OSStatus result = AudioFileOpenURL((__bridge CFURLRef)afUrl, kAudioFileReadPermission, 0, &outAFID);
#else
    OSStatus result = AudioFileOpenURL((CFURLRef)afUrl, fsRdPerm, 0, &outAFID);
#endif
    if (result != 0)
        NSLog(@"cannot openf file: %@",filePath);
    
    return outAFID;
}


// find the audio portion of the file
// return the size in bytes
-(UInt32)audioFileSize:(AudioFileID)fileDescriptor
{
    UInt64 outDataSize = 0;
    UInt32 thePropSize = sizeof(UInt64);
    OSStatus result = AudioFileGetProperty(fileDescriptor, kAudioFilePropertyAudioDataByteCount, &thePropSize, &outDataSize);
    if(result != 0)
        NSLog(@"cannot find file size");
    
    return (UInt32)outDataSize;
}


-(void)dealloc
{
    NSLog(@"dealloc() in %s", __FUNCTION__);
}

@end
