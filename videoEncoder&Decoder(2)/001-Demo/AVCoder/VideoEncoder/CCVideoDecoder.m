//
//  CCVideoDecoder.m
//  001-Demo
//
//  Created by CC老师 on 2019/2/16.
//  Copyright © 2019年 CC老师. All rights reserved.
//

#import "CCVideoDecoder.h"
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

@interface CCVideoDecoder ()
@property (nonatomic, strong) dispatch_queue_t decodeQueue;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
/**解码会话*/
@property (nonatomic) VTDecompressionSessionRef decodeSesion;

@end

@implementation CCVideoDecoder{
    uint8_t *_sps;
    NSUInteger _spsSize;
    uint8_t *_pps;
    NSUInteger _ppsSize;
    CMVideoFormatDescriptionRef _decodeDesc;
}

/**解码回调函数*/
void videoDecompressionOutputCallback(void * CM_NULLABLE decompressionOutputRefCon,
                                      void * CM_NULLABLE sourceFrameRefCon,
                                      OSStatus status,
                                      VTDecodeInfoFlags infoFlags,
                                      CM_NULLABLE CVImageBufferRef imageBuffer,
                                      CMTime presentationTimeStamp,
                                      CMTime presentationDuration ) {
    if (status != noErr) {
        NSLog(@"Video hard decode callback error status=%d", (int)status);
        return;
    }
    //解码后的数据sourceFrameRefCon -> CVPixelBufferRef
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(imageBuffer);
    
    //获取self
    CCVideoDecoder *decoder = (__bridge CCVideoDecoder *)(decompressionOutputRefCon);
    
    //调用回调队列
    dispatch_async(decoder.callbackQueue, ^{
        
        //将解码后的数据给decoder代理.viewController
        [decoder.delegate videoDecodeCallback:imageBuffer];
        //释放数据
        CVPixelBufferRelease(imageBuffer);
    });
}


- (instancetype)initWithConfig:(CCVideoConfig *)config
{
    self = [super init];
    if (self) {
        //初始化VideoConfig 信息
        _config = config;
        //创建解码队列与回调队列
        _decodeQueue = dispatch_queue_create("h264 hard decode queue", DISPATCH_QUEUE_SERIAL);
        _callbackQueue = dispatch_queue_create("h264 hard decode callback queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

/*初始化解码器**/
- (BOOL)initDecoder {
    
    if (_decodeSesion) return true;
    const uint8_t * const parameterSetPointers[2] = {_sps, _pps};
    const size_t parameterSetSizes[2] = {_spsSize, _ppsSize};
    int naluHeaderLen = 4;
    
    /**
     根据sps pps设置解码参数
     param kCFAllocatorDefault 分配器
     param 2 参数个数
     param parameterSetPointers 参数集指针
     param parameterSetSizes 参数集大小
     param naluHeaderLen nalu nalu start code 的长度 4
     param _decodeDesc 解码器描述
     return 状态
     */
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault, 2, parameterSetPointers, parameterSetSizes, naluHeaderLen, &_decodeDesc);
    if (status != noErr) {
        NSLog(@"Video hard DecodeSession create H264ParameterSets(sps, pps) failed status= %d", (int)status);
        return false;
    }
    
    /*
     解码参数:
    * kCVPixelBufferPixelFormatTypeKey:摄像头的输出数据格式
     kCVPixelBufferPixelFormatTypeKey，已测可用值为
        kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange，即420v
        kCVPixelFormatType_420YpCbCr8BiPlanarFullRange，即420f
        kCVPixelFormatType_32BGRA，iOS在内部进行YUV至BGRA格式转换
     YUV420一般用于标清视频，YUV422用于高清视频，这里的限制让人感到意外。但是，在相同条件下，YUV420计算耗时和传输压力比YUV422都小。
     
    * kCVPixelBufferWidthKey/kCVPixelBufferHeightKey: 视频源的分辨率 width*height
     * kCVPixelBufferOpenGLCompatibilityKey : 它允许在 OpenGL 的上下文中直接绘制解码后的图像，而不是从总线和 CPU 之间复制数据。这有时候被称为零拷贝通道，因为在绘制过程中没有解码的图像被拷贝.
     
     */
    NSDictionary *destinationPixBufferAttrs =
    @{
      (id)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange], //iOS上 nv12(uvuv排布) 而不是nv21（vuvu排布）
      (id)kCVPixelBufferWidthKey: [NSNumber numberWithInteger:_config.width],
      (id)kCVPixelBufferHeightKey: [NSNumber numberWithInteger:_config.height],
      (id)kCVPixelBufferOpenGLCompatibilityKey: [NSNumber numberWithBool:true]
      };
    
    //解码回调设置
    /*
     VTDecompressionOutputCallbackRecord 是一个简单的结构体，它带有一个指针 (decompressionOutputCallback)，指向帧解压完成后的回调方法。你需要提供可以找到这个回调方法的实例 (decompressionOutputRefCon)。VTDecompressionOutputCallback 回调方法包括七个参数：
            参数1: 回调的引用
            参数2: 帧的引用
            参数3: 一个状态标识 (包含未定义的代码)
            参数4: 指示同步/异步解码，或者解码器是否打算丢帧的标识
            参数5: 实际图像的缓冲
            参数6: 出现的时间戳
            参数7: 出现的持续时间
     */
    VTDecompressionOutputCallbackRecord callbackRecord;
    callbackRecord.decompressionOutputCallback = videoDecompressionOutputCallback;
    callbackRecord.decompressionOutputRefCon = (__bridge void * _Nullable)(self);
    
    //创建session
    
    /*!
     @function    VTDecompressionSessionCreate
     @abstract    创建用于解压缩视频帧的会话。
     @discussion  解压后的帧将通过调用OutputCallback发出
     @param    allocator  内存的会话。通过使用默认的kCFAllocatorDefault的分配器。
     @param    videoFormatDescription 描述源视频帧
     @param    videoDecoderSpecification 指定必须使用的特定视频解码器.NULL
     @param    destinationImageBufferAttributes 描述源像素缓冲区的要求 NULL
     @param    outputCallback 使用已解压缩的帧调用的回调
     @param    decompressionSessionOut 指向一个变量以接收新的解压会话
     */
    status = VTDecompressionSessionCreate(kCFAllocatorDefault, _decodeDesc, NULL, (__bridge CFDictionaryRef _Nullable)(destinationPixBufferAttrs), &callbackRecord, &_decodeSesion);
    
    //判断一下status
    if (status != noErr) {
        NSLog(@"Video hard DecodeSession create failed status= %d", (int)status);
        return false;
    }
    
    //设置解码会话属性(实时编码)
    status = VTSessionSetProperty(_decodeSesion, kVTDecompressionPropertyKey_RealTime,kCFBooleanTrue);
    
    NSLog(@"Vidoe hard decodeSession set property RealTime status = %d", (int)status);
    
    return true;
}

/**解码函数（private）*/
- (CVPixelBufferRef)decode:(uint8_t *)frame withSize:(uint32_t)frameSize {
    
    CVPixelBufferRef outputPixelBuffer = NULL;
    CMBlockBufferRef blockBuffer = NULL;
    CMBlockBufferFlags flag0 = 0;
    
    //创建blockBuffer
    /*!
     参数1: structureAllocator kCFAllocatorDefault
     参数2: memoryBlock  frame
     参数3: frame size
     参数4: blockAllocator: Pass NULL
     参数5: customBlockSource Pass NULL
     参数6: offsetToData  数据偏移
     参数7: dataLength 数据长度
     参数8: flags 功能和控制标志
     参数9: newBBufOut blockBuffer地址,不能为空
     */
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault, frame, frameSize, kCFAllocatorNull, NULL, 0, frameSize, flag0, &blockBuffer);
    
    if (status != kCMBlockBufferNoErr) {
        NSLog(@"Video hard decode create blockBuffer error code=%d", (int)status);
        return outputPixelBuffer;
    }
    
    CMSampleBufferRef sampleBuffer = NULL;
    const size_t sampleSizeArray[] = {frameSize};
    
    //创建sampleBuffer
    /*
     参数1: allocator 分配器,使用默认内存分配, kCFAllocatorDefault
     参数2: blockBuffer.需要编码的数据blockBuffer.不能为NULL
     参数3: formatDescription,视频输出格式
     参数4: numSamples.CMSampleBuffer 个数.
     参数5: numSampleTimingEntries 必须为0,1,numSamples 
     参数6: sampleTimingArray.  数组.为空
     参数7: numSampleSizeEntries 默认为1
     参数8: sampleSizeArray
     参数9: sampleBuffer对象
     */
    status = CMSampleBufferCreateReady(kCFAllocatorDefault, blockBuffer, _decodeDesc, 1, 0, NULL, 1, sampleSizeArray, &sampleBuffer);
    
    if (status != noErr || !sampleBuffer) {
        NSLog(@"Video hard decode create sampleBuffer failed status=%d", (int)status);
        CFRelease(blockBuffer);
        return outputPixelBuffer;
    }
    
    //解码
    //向视频解码器提示使用低功耗模式是可以的
    VTDecodeFrameFlags flag1 = kVTDecodeFrame_1xRealTimePlayback;
    //异步解码
    VTDecodeInfoFlags  infoFlag = kVTDecodeInfo_Asynchronous;
    //解码数据
    /*
     参数1: 解码session
     参数2: 源数据 包含一个或多个视频帧的CMsampleBuffer
     参数3: 解码标志
     参数4: 解码后数据outputPixelBuffer
     参数5: 同步/异步解码标识
     */
    status = VTDecompressionSessionDecodeFrame(_decodeSesion, sampleBuffer, flag1, &outputPixelBuffer, &infoFlag);
    
    if (status == kVTInvalidSessionErr) {
        NSLog(@"Video hard decode  InvalidSessionErr status =%d", (int)status);
    } else if (status == kVTVideoDecoderBadDataErr) {
        NSLog(@"Video hard decode  BadData status =%d", (int)status);
    } else if (status != noErr) {
        NSLog(@"Video hard decode failed status =%d", (int)status);
    }
    CFRelease(sampleBuffer);
    CFRelease(blockBuffer);
    
    
    return outputPixelBuffer;
}

// private
- (void)decodeNaluData:(uint8_t *)frame size:(uint32_t)size {
    //数据类型:frame的前4个字节是NALU数据的开始码，也就是00 00 00 01，
    // 第5个字节是表示数据类型，转为10进制后，7是sps, 8是pps, 5是IDR（I帧）信息
    int type = (frame[4] & 0x1F);
    
    // 将NALU的开始码转为4字节大端NALU的长度信息
    uint32_t naluSize = size - 4;
    uint8_t *pNaluSize = (uint8_t *)(&naluSize);
    CVPixelBufferRef pixelBuffer = NULL;
    frame[0] = *(pNaluSize + 3);
    frame[1] = *(pNaluSize + 2);
    frame[2] = *(pNaluSize + 1);
    frame[3] = *(pNaluSize);
    
    //第一次解析时: 初始化解码器initDecoder
    /*
     关键帧/其他帧数据: 调用[self decode:frame withSize:size] 方法
     sps/pps数据:则将sps/pps数据赋值到_sps/_pps中.
     */
    switch (type) {
        case 0x05: //关键帧
            if ([self initDecoder]) {
                pixelBuffer= [self decode:frame withSize:size];
            }
            break;
        case 0x06:
            //NSLog(@"SEI");//增强信息
            break;
        case 0x07: //sps
            _spsSize = naluSize;
            _sps = malloc(_spsSize);
            memcpy(_sps, &frame[4], _spsSize);
            break;
        case 0x08: //pps
            _ppsSize = naluSize;
            _pps = malloc(_ppsSize);
            memcpy(_pps, &frame[4], _ppsSize);
            break;
        default: //其他帧（1-5）
            if ([self initDecoder]) {
                pixelBuffer = [self decode:frame withSize:size];
            }
            break;
    }
}

// public
- (void)decodeNaluData:(NSData *)frame {
    //将解码放在异步队列.
    dispatch_async(_decodeQueue, ^{
        //获取frame 二进制数据
        uint8_t *nalu = (uint8_t *)frame.bytes;
        //调用解码Nalu数据方法,参数1:数据 参数2:数据长度
        [self decodeNaluData:nalu size:(uint32_t)frame.length];
    });
}

//销毁
- (void)dealloc
{
    if (_decodeSesion) {
        VTDecompressionSessionInvalidate(_decodeSesion);
        CFRelease(_decodeSesion);
        _decodeSesion = NULL;
    }
    
}

/**
 nal_unit_type  NAL类型                         C
 0              未使用
 1              非IDR图像中不采用数据划分的片段     2,3,4
 2              非IDR图像中A类数据划分片段         2
 3              非IDR图像中B类数据划分片段         3
 4              非IDR图像中C类数据划分片段         4
 5              IDR图像的片                     2,3
 6              补充增强信息单元（SEI）           5
 7              序列参数集                       0
 8              图像参数集                       1
 9              分界符                          6
 10             序列结束                         7
 11             码流结束                        8
 12             填充                            9
 13..23         保留
 
 24..31        不保留（RTP打包时会用到）
 
 
 NSString * const naluTypesStrings[] =
 {
 @"0: Unspecified (non-VCL)",
 @"1: Coded slice of a non-IDR picture (VCL)",    // P frame
 @"2: Coded slice data partition A (VCL)",
 @"3: Coded slice data partition B (VCL)",
 @"4: Coded slice data partition C (VCL)",
 @"5: Coded slice of an IDR picture (VCL)",      // I frame
 @"6: Supplemental enhancement information (SEI) (non-VCL)",
 @"7: Sequence parameter set (non-VCL)",         // SPS parameter
 @"8: Picture parameter set (non-VCL)",          // PPS parameter
 @"9: Access unit delimiter (non-VCL)",
 @"10: End of sequence (non-VCL)",
 @"11: End of stream (non-VCL)",
 @"12: Filler data (non-VCL)",
 @"13: Sequence parameter set extension (non-VCL)",
 @"14: Prefix NAL unit (non-VCL)",
 @"15: Subset sequence parameter set (non-VCL)",
 @"16: Reserved (non-VCL)",
 @"17: Reserved (non-VCL)",
 @"18: Reserved (non-VCL)",
 @"19: Coded slice of an auxiliary coded picture without partitioning (non-VCL)",
 @"20: Coded slice extension (non-VCL)",
 @"21: Coded slice extension for depth view components (non-VCL)",
 @"22: Reserved (non-VCL)",
 @"23: Reserved (non-VCL)",
 @"24: STAP-A Single-time aggregation packet (non-VCL)",
 @"25: STAP-B Single-time aggregation packet (non-VCL)",
 @"26: MTAP16 Multi-time aggregation packet (non-VCL)",
 @"27: MTAP24 Multi-time aggregation packet (non-VCL)",
 @"28: FU-A Fragmentation unit (non-VCL)",
 @"29: FU-B Fragmentation unit (non-VCL)",
 @"30: Unspecified (non-VCL)",
 @"31: Unspecified (non-VCL)",
 };
 */


@end
