//
//  SystemCaptureManager.m
//  demo11
//
//  Created by pengchao on 2022/6/23.
//

#import "SystemCaptureManager.h"

@interface VideoConfig ()
@property (nonatomic,assign,readwrite) NSInteger width;
@property (nonatomic,assign,readwrite) NSInteger height;
@end

@implementation VideoConfig
+(instancetype)defaulConfig{
    return [[VideoConfig alloc]init];
}

- (instancetype)init{
    self = [super init];
    if (self) {
        CGSize presetSize = [self sizeWithPresent:AVCaptureSessionPreset1280x720];
        self.present = AVCaptureSessionPreset1280x720;
        self.width = (NSUInteger) presetSize.width;
        self.height = (NSUInteger)presetSize.height;
        self.bitRate = presetSize.width * presetSize.height * 3 *4;
        self.fps = 25;
    }
    return self;
}

- (CGSize)sizeWithPresent:(AVCaptureSessionPreset )present{
    if (present == AVCaptureSessionPreset640x480) {
        return CGSizeMake(480, 640);
    } else if (present == AVCaptureSessionPreset1280x720){
        return CGSizeMake(720, 1280);
    } else if (present == AVCaptureSessionPreset1920x1080){
        return CGSizeMake(1080, 1920);
    } else if (present == AVCaptureSessionPreset3840x2160){
        return CGSizeMake(2160, 3840);
    } else {
        return CGSizeZero;
    }
}

@end

@implementation AudioConfig
+(instancetype)defaulConfig{
    return [[AudioConfig alloc]init];
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.bitRate = 96000;
        self.channelCount = 1;
        self.sampleSize = 16;
        self.sampleRate = 44100;
    }
    return self;
}

@end

 


@interface SystemCaptureManager()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
{
    SystemCaptureType _capture;
    VideoConfig *_videoConfig;
    AudioConfig *_audioConfig;
}

@property (nonatomic,assign,readwrite) NSInteger width;
@property (nonatomic,assign,readwrite) NSInteger height;
@property (nonatomic, strong) dispatch_queue_t captureQueue;

@property (nonatomic ,assign) BOOL isRunning;
@property (nonatomic ,strong) AVCaptureSession *captureSession;

/// 音频
@property (nonatomic, strong) AVCaptureDeviceInput *audioInputDevice;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;

/// 视频
@property (nonatomic, weak) AVCaptureDeviceInput *videoInputDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *frontCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *backCamera;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;

/// 预览
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preLayer;
@property (nonatomic, assign) CGSize preLayerSize;

@end


@implementation SystemCaptureManager




- (instancetype)initWithType:(SystemCaptureType)type videoConfig:(VideoConfig *)videoConfig audioConfig:(AudioConfig *)audioConfig{
    self = [super init];
    if (self) {
        _capture = type;
        _videoConfig = videoConfig;
        _audioConfig = audioConfig;
    }
    return self;
}

- (void)start {
    if (!self.isRunning) {
        self.isRunning = YES;
        [self.captureSession startRunning];
    }
}

- (void)stop {
    if (self.isRunning) {
        self.isRunning = NO;
        [self.captureSession stopRunning];
    }
    
}

#pragma mark-public 

- (void)prepareWithPreviewSize:(CGSize)size {
    _preLayerSize = size;
    if (_capture == SystemCaptureTypeAudio) {
        [self setupAudio];
    }else if (_capture == SystemCaptureTypeVideo) {
        [self setupVideo];
    }else if (_capture == SystemCaptureTypeAll) {
        [self setupAudio];
        [self setupVideo];
    }
}

+ (int)checkCameraAuthor {
    int result = 0;
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (videoStatus) {
        case AVAuthorizationStatusNotDetermined://第一次
            //    请求授权
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                
            }];
            break;
        case AVAuthorizationStatusAuthorized://已授权
            result = 1;
            break;
        default:
            result = -1;
            break;
    }
    return result;
    
}


#pragma mark-didOutputSampleBuffer

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (connection == self.audioConnection) {
        [_delegate captureSampleBuffer:sampleBuffer type:SystemCaptureTypeAudio];
    } else if (connection == self.videoConnection) {
        [_delegate captureSampleBuffer:sampleBuffer type:SystemCaptureTypeVideo];
    }
}



#pragma mark-private


-(void)initPrepare{
    if (_capture == SystemCaptureTypeAudio) {
        [self setupAudio];
    }else if (_capture == SystemCaptureTypeVideo) {
        [self setupVideo];
    }else if (_capture == SystemCaptureTypeAll) {
        [self setupAudio];
        [self setupVideo];
    }
}

-(void)setupAudio{
   //麦克风设备
   AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
   //将audioDevice ->AVCaptureDeviceInput 对象
   self.audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
   //音频输出
   self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
   [self.audioDataOutput setSampleBufferDelegate:self queue:self.captureQueue];
   //配置
   [self.captureSession beginConfiguration];
   if ([self.captureSession canAddInput:self.audioInputDevice]) {
       [self.captureSession addInput:self.audioInputDevice];
   }
   if([self.captureSession canAddOutput:self.audioDataOutput]){
       [self.captureSession addOutput:self.audioDataOutput];
   }
   [self.captureSession commitConfiguration];
   
   self.audioConnection = [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
}

- (void)setupVideo{
   //所有video设备
   NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
   //前置摄像头
   self.frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.lastObject error:nil];
   self.backCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.firstObject error:nil];
   //设置当前设备为前置
   self.videoInputDevice = self.backCamera;
   //视频输出
   self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
   [self.videoDataOutput setSampleBufferDelegate:self queue:self.captureQueue];
   [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
   //kCVPixelBufferPixelFormatTypeKey它指定像素的输出格式，这个参数直接影响到生成图像的成功与否
  // kCVPixelFormatType_420YpCbCr8BiPlanarFullRange  YUV420格式.
   
   [self.videoDataOutput setVideoSettings:@{
                                            (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                                            }];
   //配置
   [self.captureSession beginConfiguration];
   if ([self.captureSession canAddInput:self.videoInputDevice]) {
       [self.captureSession addInput:self.videoInputDevice];
   }
   if([self.captureSession canAddOutput:self.videoDataOutput]){
       [self.captureSession addOutput:self.videoDataOutput];
   }
   
   //分辨率
   [self setVideoPreset];
   [self.captureSession commitConfiguration];
   //commit后下面的代码才会有效
   self.videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
   //设置视频输出方向
   self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
   
   //fps
   [self updateFps:25];
   //设置预览
   [self setupPreviewLayer];
}

/**设置预览层**/
- (void)setupPreviewLayer{
    self.preLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.preLayer.frame =  CGRectMake(0, 0, self.preLayerSize.width, self.preLayerSize.height);
    //设置满屏
    self.preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.preview.layer addSublayer:self.preLayer];
}


/**设置分辨率**/
- (void)setVideoPreset{
    if ([self.captureSession canSetSessionPreset:_videoConfig.present])  {
        self.captureSession.sessionPreset =_videoConfig.present;
        self.width = _videoConfig.width ; self.height = _videoConfig.height;
    } else {
        self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        self.width = 480; self.height = 640;
    }
    
}

-(void)updateFps:(NSInteger) fps{
    //获取当前capture设备
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    //遍历所有设备（前后摄像头）
    for (AVCaptureDevice *vDevice in videoDevices) {
        //获取当前支持的最大fps
        float maxRate = [(AVFrameRateRange *)[vDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0] maxFrameRate];
        //如果想要设置的fps小于或等于做大fps，就进行修改
        if (maxRate >= fps) {
            //实际修改fps的代码
            if ([vDevice lockForConfiguration:NULL]) {
                vDevice.activeVideoMinFrameDuration = CMTimeMake(10, (int)(fps * 10));
                vDevice.activeVideoMaxFrameDuration = vDevice.activeVideoMinFrameDuration;
                [vDevice unlockForConfiguration];
            }
        }
    }
}


#pragma mark-懒加载
- (AVCaptureSession *)captureSession{
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return _captureSession;
}
- (dispatch_queue_t)captureQueue{
    if (!_captureQueue) {
        _captureQueue = dispatch_queue_create("TMCapture Queue", NULL);
    }
    return _captureQueue;
}
- (UIView *)preview{
    if (!_preview) {
        _preview = [[UIView alloc] init];
    }
    return _preview;
}


@end
