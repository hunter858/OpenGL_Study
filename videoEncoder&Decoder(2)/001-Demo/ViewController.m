//
//  ViewController.m
//  001-Demo
//
//  Created by CC老师 on 2019/2/16.
//  Copyright © 2019年 CC老师. All rights reserved.
//

#import "ViewController.h"
#import "CCSystemCapture.h"
#import "CCAudioEncoder.h"
#import "CCAudioDecoder.h"
#import "CCAudioPCMPlayer.h"

#import "CCAVConfig.h"

#import "CCVideoEncoder.h"
#import "CCVideoDecoder.h"
#import "AAPLEAGLLayer.h"
@interface ViewController ()<CCSystemCaptureDelegate,CCVideoEncoderDelegate, CCVideoDecoderDelegate>

@property (nonatomic, strong) CCSystemCapture *capture;


@property (nonatomic, strong) CCVideoEncoder *videoEncoder;
@property (nonatomic, strong) CCVideoDecoder *videoDecoder;
@property (nonatomic, strong) CCAudioEncoder *audioEncoder;
@property (nonatomic, strong) AAPLEAGLLayer *displayLayer;
@property (nonatomic, strong) CCAudioDecoder *audioDecoder;
@property (nonatomic, strong) CCAudioPCMPlayer *pcmPlayer;

@property (nonatomic, strong) NSFileHandle *handle;
@property (nonatomic, copy) NSString *path;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    
    [self testVideo];
}

#pragma mark - Video Test
- (void)testVideo {
    
    //    测试写入文件
    _path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"h264test.h264"];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:_path]) {
        if ([manager removeItemAtPath:_path error:nil]) {
            NSLog(@"删除成功");
            if ([manager createFileAtPath:_path contents:nil attributes:nil]) {
                NSLog(@"创建文件");
            }
        }
    }else {
        if ([manager createFileAtPath:_path contents:nil attributes:nil]) {
            NSLog(@"创建文件");
        }
    }
    
    NSLog(@"%@", _path);
    _handle = [NSFileHandle fileHandleForWritingAtPath:_path];
    [CCSystemCapture checkCameraAuthor];
    
    //捕获媒体
    _capture = [[CCSystemCapture alloc] initWithType:CCSystemCaptureTypeVideo];//这是我只捕获了视频
    CGSize size = CGSizeMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    [_capture prepareWithPreviewSize:size];  //捕获视频时传入预览层大小
    _capture.preview.frame = CGRectMake(0, 100, size.width, size.height);
    [self.view addSubview:_capture.preview];
    self.capture.delegate = self;
    
    CCVideoConfig *config = [CCVideoConfig defaultConifg];
    config.width = _capture.witdh;
    config.height = _capture.height;
    config.bitrate = config.height * config.width * 5;
    
    _videoEncoder = [[CCVideoEncoder alloc] initWithConfig:config];
    _videoEncoder.delegate = self;
    
    _videoDecoder = [[CCVideoDecoder alloc] initWithConfig:config];
    _videoDecoder.delegate = self;
    
    //aac编码器
    _audioEncoder = [[CCAudioEncoder alloc] initWithConfig:[CCAudioConfig defaultConifg]];
    _audioEncoder.delegate = self;
    
    _audioDecoder = [[CCAudioDecoder alloc]initWithConfig:[CCAudioConfig defaultConifg]];
    _audioDecoder.delegate = self;
    
    
    _pcmPlayer = [[CCAudioPCMPlayer alloc]initWithConfig:[CCAudioConfig defaultConifg]];
    
    _displayLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(size.width, 100, size.width, size.height)];
    [self.view.layer addSublayer:_displayLayer];
}
//开始捕捉
- (IBAction)startCapture:(id)sender {
     [self.capture start];
}

//结束捕捉
- (IBAction)stopCapture:(id)sender {
    [self.capture stop];
}

//关闭文件
- (IBAction)closeFile:(id)sender {
     [_handle closeFile];
}

#pragma mark--delegate
//捕获音视频回调
- (void)captureSampleBuffer:(CMSampleBufferRef)sampleBuffer type: (CCSystemCaptureType)type {
    if (type == CCSystemCaptureTypeAudio) {
        //音频数据
        //1.直接播放PCM数据
         NSData *pcmData = [self convertAudioSamepleBufferToPcmData:sampleBuffer];
         [_pcmPlayer playPCMData:pcmData];
        
        //2.AAC编码
        [_audioEncoder encodeAudioSamepleBuffer:sampleBuffer];
        
    
    }else {
        [_videoEncoder encodeVideoSampleBuffer:sampleBuffer];
    }
}
//将sampleBuffer数据提取出PCM数据返回给ViewController.可以直接播放PCM数据
- (NSData *)convertAudioSamepleBufferToPcmData: (CMSampleBufferRef)sampleBuffer {
    
    //获取pcm数据大小
    size_t size = CMSampleBufferGetTotalSampleSize(sampleBuffer);
    //分配空间
    int8_t *audio_data = (int8_t *)malloc(size);
    memset(audio_data, 0, size);
    
    //获取CMBlockBuffer, 这里面保存了PCM数据
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    //将数据copy到我们分配的空间中
    CMBlockBufferCopyDataBytes(blockBuffer, 0, size, audio_data);
    //PCM data->NSData
    NSData *data = [NSData dataWithBytes:audio_data length:size];
    free(audio_data);
    return data;
}
#pragma mark--CCAudioEncoder/Decoder Delegate
//aac编码回调
- (void)audioEncodeCallback:(NSData *)aacData {
 
     //1.写入文件
    // [_handle seekToEndOfFile];
    // [_handle writeData:aacData];

    //2.直接解码
    [_audioDecoder decodeAudioAACData:aacData];
    
}



#pragma mark--CCVideoEncoder/Decoder Delegate
//h264编码回调（sps/pps）
- (void)videoEncodeCallbacksps:(NSData *)sps pps:(NSData *)pps {
    //解码
    [_videoDecoder decodeNaluData:sps];
    
    //    测试写入文件
    //    [_handle seekToEndOfFile];
    //    [_handle writeData:sps];
    
    //解码（这两个不能直接和在一起解码）
    [_videoDecoder decodeNaluData:pps];
    
    //    [_handle seekToEndOfFile];
    //    [_handle writeData:pps];
}
//h264编码回调 （数据）
- (void)videoEncodeCallback:(NSData *)h264Data {
    //编码
    [_videoDecoder decodeNaluData:h264Data];
    //    测试写入文件
    //    [_handle seekToEndOfFile];
    //    [_handle writeData:h264Data];
}

//h264解码回调
- (void)videoDecodeCallback:(CVPixelBufferRef)imageBuffer {
    //显示
    if (imageBuffer) {
        _displayLayer.pixelBuffer = imageBuffer;
    }
    
}



@end
