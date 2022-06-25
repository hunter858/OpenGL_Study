//
//  AudioHWEncoder.m
//  demo11
//
//  Created by pengchao on 2022/6/23.
//

#import "AudioEncoder.h"


#define BytesPerPacket 2
#define AACFramePerPacket 1024

static int pcmBufferSize = 0;
static uint8_t pcmBuffer[BytesPerPacket * AACFramePerPacket * 8];

@interface AudioEncoder ()
@property (nonatomic, strong) dispatch_queue_t encoderQueue;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;

//对音频转换器对象
@property (nonatomic, unsafe_unretained) AudioConverterRef audioConverter;
//PCM缓存区
//@property (nonatomic) char *pcmBuffer;
//PCM缓存区大小
//@property (nonatomic) size_t pcmBufferSize;

@end

@implementation AudioEncoder
- (instancetype)initWithConfig:(AudioConfig *)config{
    self = [super init];
    if (self) {
        _encoderQueue = dispatch_queue_create("aac hard encoder queue", DISPATCH_QUEUE_SERIAL);
        //音频回调队列
        _callbackQueue = dispatch_queue_create("aac hard encoder callback queue", DISPATCH_QUEUE_SERIAL);
        //音频转换器
        _audioConverter = NULL;
        self.audioConfig = config;
        if (config == nil) {
            self.audioConfig = [[AudioConfig  alloc] init];
        }
    }
    return self;
}


static OSStatus aacEncodeInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData){
    AudioBufferList bufferList = *(AudioBufferList *)inUserData;
    ioData->mNumberBuffers = bufferList.mNumberBuffers;
    ioData->mBuffers[0].mNumberChannels = bufferList.mBuffers->mNumberChannels;
    ioData->mBuffers[0].mData = bufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = bufferList.mBuffers[0].mDataByteSize;
    return noErr;
}


- (void)encodeAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer  {
    __weak typeof(self) weakSelf = self;
    
    // 获取PCM 数据到 inputPcmBuffer 缓冲区
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t  inputPCMLength = 0;
    char *inputPcmBuffer;
    OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &inputPCMLength, &inputPcmBuffer);
    if (status != kCMBlockBufferNoErr) {
         NSLog(@"Get ACC from blockBuffer error \n");
    }
    
    // 开辟AAC 缓冲空间并初始化
    uint8_t *aacBuffer = malloc(inputPCMLength);
    memset(aacBuffer, 0, inputPCMLength);
    
    // 将PCM 数据放入缓冲队列，并记录当前缓冲区的大小
    memcpy(pcmBuffer + pcmBufferSize, inputPcmBuffer, inputPCMLength);
    pcmBufferSize += inputPCMLength;
    
     
   
    size_t maxBufferSize = BytesPerPacket * AACFramePerPacket * self.audioConfig.channelCount;
    NSMutableData *rawAAC = [NSMutableData new];
    
    if (pcmBufferSize >= maxBufferSize) {
        NSUInteger count = pcmBufferSize / maxBufferSize;
        for (NSInteger index = 0; index < count; index++) {
            
            UInt8 *aacBuffer = malloc(maxBufferSize);
            memset(aacBuffer, 0, maxBufferSize);
         
            AudioBufferList inputBufferlist ;
            inputBufferlist.mNumberBuffers = 1;
            inputBufferlist.mBuffers ->mNumberChannels = (UInt32) self.audioConfig.channelCount;
            inputBufferlist.mBuffers->mDataByteSize = (UInt32)maxBufferSize;
            inputBufferlist.mBuffers->mData = pcmBuffer;
            
            AudioBufferList outputBufferlist ;
            outputBufferlist.mNumberBuffers = 1;
            outputBufferlist.mBuffers ->mNumberChannels = inputBufferlist.mBuffers->mNumberChannels;
            outputBufferlist.mBuffers->mDataByteSize =  (UInt32)maxBufferSize;
            outputBufferlist.mBuffers->mData = aacBuffer;
            
            UInt32 outputNumPackets = 1;
           
            OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, aacEncodeInputDataProc, &inputBufferlist, &outputNumPackets, &outputBufferlist, NULL);
            if (status != noErr) {
                NSLog(@"audio converter fillComplexBuffer error %d",status);
            }
            [rawAAC appendBytes:outputBufferlist.mBuffers[0].mData length:outputBufferlist.mBuffers[0].mDataByteSize];
            NSUInteger leftBufferSize = pcmBufferSize - maxBufferSize;
            if (leftBufferSize > 0) {
                memcpy(pcmBuffer, pcmBuffer + maxBufferSize, leftBufferSize);
            }
            pcmBufferSize -= maxBufferSize;
        }
        dispatch_async(_callbackQueue, ^{
            [weakSelf delegateWithAACData:rawAAC];
        });
    }
}



- (void)encodeAudioData:(NSData *)pcmData{
    __weak typeof(self) weakSelf = self;
    
    NSMutableData *rawAAC = [NSMutableData new];
    
   size_t maxBufferSize = BytesPerPacket * AACFramePerPacket * self.audioConfig.channelCount;
    
    memcpy(pcmBuffer + pcmBufferSize, pcmData.bytes, pcmData.length);
    pcmBufferSize += pcmData.length;
    
    if (pcmBufferSize >= maxBufferSize) {
        NSUInteger count = pcmBufferSize / maxBufferSize;
        for (NSInteger index = 0; index < count; index++) {
            
            UInt8 *aacBuffer = malloc(maxBufferSize);
            memset(aacBuffer, 0, maxBufferSize);
         
            AudioBufferList inputBufferlist ;
            inputBufferlist.mNumberBuffers = 1;
            inputBufferlist.mBuffers ->mNumberChannels = (UInt32) self.audioConfig.channelCount;
            inputBufferlist.mBuffers->mDataByteSize = (UInt32) maxBufferSize;
            inputBufferlist.mBuffers->mData = pcmBuffer;
            
            AudioBufferList outputBufferlist ;
            outputBufferlist.mNumberBuffers = 1;
            outputBufferlist.mBuffers ->mNumberChannels = inputBufferlist.mBuffers->mNumberChannels;
            outputBufferlist.mBuffers->mDataByteSize = (UInt32) maxBufferSize;
            outputBufferlist.mBuffers->mData = aacBuffer;
            
            UInt32 outputNumPackets = 1;
           
            OSStatus status = AudioConverterFillComplexBuffer(_audioConverter, aacEncodeInputDataProc, &inputBufferlist, &outputNumPackets, &outputBufferlist, NULL);
            if (status != noErr) {
                NSLog(@"audio converter fillComplexBuffer error %d",status);
            }
            [rawAAC appendBytes:outputBufferlist.mBuffers[0].mData length:outputBufferlist.mBuffers[0].mDataByteSize];
            NSUInteger leftBufferSize = pcmBufferSize - maxBufferSize;
            if (leftBufferSize > 0) {
                memcpy(pcmBuffer, pcmBuffer + maxBufferSize, leftBufferSize);
            }
            pcmBufferSize -= maxBufferSize;
        }
        dispatch_async(_callbackQueue, ^{
            [weakSelf delegateWithAACData:rawAAC];
        });
    }
}


- (void)delegateWithAACData:(NSData *)aacData {
    if ([self.delegate respondsToSelector:@selector(audioEncodeCallback:)]) {
        [self.delegate audioEncodeCallback:aacData];
    }
}


-(void)start {
    //设置输入源 PCM 的音频参数
    AudioStreamBasicDescription inputAudioDes = {0};
    inputAudioDes.mSampleRate = self.audioConfig.sampleRate;
    inputAudioDes.mFormatID = kAudioFormatLinearPCM;
    inputAudioDes.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    inputAudioDes.mChannelsPerFrame = (uint32_t)self.audioConfig.channelCount;
    inputAudioDes.mBitsPerChannel = (uint32_t)self.audioConfig.sampleSize;
    inputAudioDes.mFramesPerPacket = 1;
    inputAudioDes.mBitsPerChannel = 16;
    inputAudioDes.mBytesPerFrame = inputAudioDes.mBitsPerChannel / 8 * inputAudioDes.mChannelsPerFrame;
    inputAudioDes.mBytesPerPacket = inputAudioDes.mBytesPerFrame * inputAudioDes.mFramesPerPacket;;
    
    //设置输出AAC 的编码参数
    AudioStreamBasicDescription outputAudioDes = {0};
    outputAudioDes.mFormatID = kAudioFormatMPEG4AAC;
    outputAudioDes.mFormatFlags = kMPEG4Object_AAC_LC;
    outputAudioDes.mSampleRate = self.audioConfig.sampleRate;
    outputAudioDes.mChannelsPerFrame = (uint32_t)self.audioConfig.channelCount;  ///声道数
    outputAudioDes.mFramesPerPacket = 1024;///每个packet 的帧数 ，这是一个比较大的固定数值
    outputAudioDes.mBytesPerFrame = 0; //每帧的大小  如果是压缩格式设置为0
    outputAudioDes.mReserved = 0; // 8字节对齐，填0;
    

    
    uint32_t outDesSize = sizeof(outputAudioDes);
    AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &outDesSize, &outputAudioDes);
    OSStatus status = AudioConverterNew(&inputAudioDes, &outputAudioDes, &_audioConverter);
    if (status != noErr) {
        NSLog(@"硬编码AAC创建失败");
    }
    
    //设置码率
    uint32_t aBitrate = (uint32_t)self.audioConfig.bitRate;
    uint32_t aBitrateSize = sizeof(aBitrate);
    status = AudioConverterSetProperty(_audioConverter, kAudioConverterEncodeBitRate, aBitrateSize, &aBitrate);
    
    pcmBufferSize = 0;
}

- (void)stop {
    AudioConverterDispose(_audioConverter);
    _audioConverter = nil;
    pcmBufferSize = 0;
}

- (NSData *)ADTSHeaderWithLength:(int)data_length {
    NSInteger profile = self.audioConfig.sampleSize/8;
    return  [self adtsHeaderWithLength:data_length profile:profile sampleRate:self.audioConfig.sampleRate channles:self.audioConfig.channelCount];
}



- (NSData *)adtsHeaderWithLength:(int)data_length profile:(int)profile sampleRate:(int)sampleRate channles:(int)channles {
    
    int adtsLength = 7;
    profile = 2;  /// AAC LC
    int chanCfg = 1;
    char *adts_header = malloc(sizeof(char) * adtsLength);
    int fullLength = adtsLength + data_length;
    int freqIdx = [self fregWithSampleBuffer:sampleRate];    //对应44100采样率；
    /*
    A 12 syncword 0xFFF, all bits must be 1
    //  11111111
    */
    adts_header[0] = 0xFF;
    /*
    B 1 MPEG Version: 0 for MPEG-4, 1 for MPEG-2
    C 2 Layer: always 0
    D 1 protection absent, Warning, set to 1 if there is no CRC and 0 if there is CRC
    ///  1111 1001
    */
    adts_header[1] = 0xF9;
    /*
    E 2 profile, the MPEG-4 Audio Object Type minus 1
    F 4 MPEG-4 Sampling Frequency Index (15 is forbidden)
    G 1 private bit, guaranteed never to be used by MPEG, set to 0 when encoding, ignore when decoding
    H 3 MPEG-4 Channel Configuration (in the case of 0, the channel configuration is sent via an inband
     11
    */
    adts_header[2] = (char)(((profile-1) << 6));
    adts_header[2] |= (char)(freqIdx << 2);
    adts_header[2] |= (char)(chanCfg >> 2);
    
    /*
      前两位已经被H占了
     I 1 originality, set to 0 when encoding, ignore when decoding
     J 1 home, set to 0 when encoding, ignore when decoding
     K 1 copyrighted id bit, the next bit of a centrally registered copyright identifier, set to 0 when encoding, ignore when decoding
     L 1 copyright id start, signals that this frame's copyright id bit is the first bit of the copyright id, set to 0 when encoding, ignore when decoding

     xx0000xx
     */
    adts_header[3] = (char)((chanCfg & 3) <<6); //chanCfg 的2bit
    
    /*
     M 13 frame length, this value must include 7 or 9 bytes of header length: FrameLength = (ProtectionAbsent == 1 ? 7 : 9) + size(AACFrame)
     0x7FF = 11111111111
     */
    adts_header[3]  |= (char)((fullLength & 0x18) >> 11);//这里只占了2bit 所以，13bit 又移11位
    adts_header[4] = (char)((fullLength &0x7FF) >> 3);
   
    //前3bit 是fulllength 的低位
    adts_header[5] =  (char)((fullLength & 7) << 5);
    /*
     O 11 Buffer fullness
     */
    adts_header[5] |= 0x1f;
    /*
     Q 16 CRC if protection absent is 0
     */
    adts_header[6] = (char)0xFC;
    
    NSData *data = [[NSData alloc] initWithBytes:adts_header length:adtsLength];
    return data;
}

- (int)fregWithSampleBuffer:(NSUInteger)sampelBuffer {
    char value = 0x0;
    if (sampelBuffer == 96000)     { value = 0x0; }
    else if (sampelBuffer == 88200){ value = 0x1; }
    else if (sampelBuffer == 64000){ value = 0x2; }
    else if (sampelBuffer == 48000){ value = 0x3; }
    else if (sampelBuffer == 44100){ value = 0x4; }
    else if (sampelBuffer == 32000){ value = 0x5; }
    else if (sampelBuffer == 24000){ value = 0x6; }
    else if (sampelBuffer == 22050){ value = 0x7; }
    else if (sampelBuffer == 16000){ value = 0x8; }
    else if (sampelBuffer == 12000){ value = 0x9; }
    else if (sampelBuffer == 11025){ value = 0xa; }
    else if (sampelBuffer == 8000) { value = 0xb; }
    return value;
}


@end
