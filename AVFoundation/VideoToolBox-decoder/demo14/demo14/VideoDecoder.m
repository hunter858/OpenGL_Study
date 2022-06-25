//
//  VideoDecoder.m
//  demo14
//
//  Created by pengchao on 2022/6/24.
//

#import "VideoDecoder.h"
@interface VideoDecoder ()
{
    NSData *_sps;
    NSData *_pps;
    VTDecompressionSessionRef  _decodeSession;
    dispatch_queue_t _decodeCallbackQueue;
    CMFormatDescriptionRef _formatDescriptionOut;
}
@end

@implementation VideoDecoder
- (instancetype)initWithSps:(NSData *)sps pps:(NSData *)pps {
    self = [super init];
    if (self) {
        _sps = sps;
        _pps = pps;
        _decodeCallbackQueue = dispatch_queue_create("videoToolBox.decoder.queue", NULL);
        [self initVideoToolBox];
    }
    return self;
}


static void decodeCompressionOutputCallback(void * CM_NULLABLE decompressionOutputRefCon,
                                      void * CM_NULLABLE sourceFrameRefCon,
                                      OSStatus status,
                                      VTDecodeInfoFlags infoFlags,
                                      CM_NULLABLE CVImageBufferRef imageBuffer,
                                      CMTime presentationTimeStamp,
                                      CMTime presentationDuration ){
    
    VideoDecoder *self = (__bridge VideoDecoder *)(decompressionOutputRefCon);
    dispatch_queue_t callbackQuque = self ->_decodeCallbackQueue;
    
    CIImage *ciimage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    UIImage *image = [UIImage imageWithCIImage:ciimage];
    if (imageBuffer && [self.delegate respondsToSelector:@selector(videoDecoderCallbackPixelBuffer:)]) {
        CIImage *ciimage = [CIImage imageWithCVPixelBuffer:imageBuffer];
        UIImage *image = [UIImage imageWithCIImage:ciimage];
        dispatch_async(callbackQuque, ^{
            [self.delegate videoDecoderCallbackPixelBuffer:image];
        });
    }
}

-(void)initVideoToolBox {
    
    if (_decodeSession) {
        return;
    }
    
    CMFormatDescriptionRef formatDescriptionOut;
    const uint8_t * const param[2] = {_sps.bytes,_pps.bytes};
    const size_t paramSize[2] = {_sps.length,_pps.length};
    OSStatus formateStatus =
    CMVideoFormatDescriptionCreateFromH264ParameterSets(NULL,
                                                        2,
                                                        param,
                                                        paramSize,
                                                        4,
                                                        &formatDescriptionOut);
    _formatDescriptionOut = formatDescriptionOut;
    
    if (formateStatus!=noErr) {
        NSLog(@"FormatDescriptionCreate fail");
        return;
    }
    //2. 创建VTDecompressionSessionRef
    //确定编码格式
    const void *keys[] = {kCVPixelBufferPixelFormatTypeKey};
    
    uint32_t t = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    const void *values[] = {CFNumberCreate(NULL, kCFNumberSInt32Type, &t)};
    
    CFDictionaryRef att = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    
    VTDecompressionOutputCallbackRecord VTDecompressionOutputCallbackRecord;
    VTDecompressionOutputCallbackRecord.decompressionOutputCallback = decodeCompressionOutputCallback;
    VTDecompressionOutputCallbackRecord.decompressionOutputRefCon = (__bridge void * _Nullable)(self);
    
    OSStatus sessionStatus = VTDecompressionSessionCreate(NULL,
                                 formatDescriptionOut,
                                 NULL,
                                 att,
                                 &VTDecompressionOutputCallbackRecord,
                                 &_decodeSession);
    CFRelease(att);
    if (sessionStatus != noErr) {
        NSLog(@"SessionCreate fail");
        [self endDecode];
    }
}

- (void)endDecode {
    
}


- (void)decoderWithData:(NSData *)data{
    if (!_decodeSession) {
        return;
    }
    //1.创建CMBlockBufferRef
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus blockBufferStatus =
    CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                       data.bytes,
                                       data.length,
                                       NULL,
                                       NULL,
                                       0,
                                       data.length,
                                       0,
                                       &blockBuffer);
    if (blockBufferStatus!=noErr) {
        NSLog(@"BolkBufferCreate fail");
        return;
    }
    //2.创建CMSampleBufferRef
    CMSampleBufferRef sampleBuffer = NULL;
    const size_t sampleSizeArray[] = {data.length};
    OSStatus sampleBufferStatus =
    CMSampleBufferCreateReady(kCFAllocatorDefault,
                              blockBuffer,
                              _formatDescriptionOut,
                              1, //sample 的数量
                              0, //sampleTimingArray 的长度
                              NULL, //sampleTimingArray 对每一个设置一些属性，这些我们并不需要
                              1, //sampleSizeArray 的长度
                              sampleSizeArray,
                              &sampleBuffer);
    
    if (blockBuffer && sampleBufferStatus == kCMBlockBufferNoErr) {
        //3.编码生成
        VTDecodeFrameFlags flags = 0;
        VTDecodeInfoFlags flagOut = 0;
        OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_decodeSession,
                                          sampleBuffer,flags,
                                          NULL,
                                          &flagOut); //receive information about the decode operation
        if (decodeStatus!= noErr) {
            NSLog(@"DecodeFrame fail %d",(int)decodeStatus);
            return;
        }
    }
    if (sampleBufferStatus != noErr) {
        NSLog(@"SampleBufferCreate fail");
        return;
    }
}

@end
