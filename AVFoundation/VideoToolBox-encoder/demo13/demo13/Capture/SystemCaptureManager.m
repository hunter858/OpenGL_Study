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

/// ??????
@property (nonatomic, strong) AVCaptureDeviceInput *audioInputDevice;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;

/// ??????
@property (nonatomic, weak) AVCaptureDeviceInput *videoInputDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *frontCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *backCamera;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;

/// ??????
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
        case AVAuthorizationStatusNotDetermined://?????????
            //    ????????????
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                
            }];
            break;
        case AVAuthorizationStatusAuthorized://?????????
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
   //???????????????
   AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
   //???audioDevice ->AVCaptureDeviceInput ??????
   self.audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
   //????????????
   self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
   [self.audioDataOutput setSampleBufferDelegate:self queue:self.captureQueue];
   //??????
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
   //??????video??????
   NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
   //???????????????
   self.frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.lastObject error:nil];
   self.backCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.firstObject error:nil];
   //???????????????????????????
   self.videoInputDevice = self.backCamera;
   //????????????
   self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
   [self.videoDataOutput setSampleBufferDelegate:self queue:self.captureQueue];
   [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
   //kCVPixelBufferPixelFormatTypeKey???????????????????????????????????????????????????????????????????????????????????????
  // kCVPixelFormatType_420YpCbCr8BiPlanarFullRange  YUV420??????.
   
   [self.videoDataOutput setVideoSettings:@{
                                            (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
                                            }];
   //??????
   [self.captureSession beginConfiguration];
   if ([self.captureSession canAddInput:self.videoInputDevice]) {
       [self.captureSession addInput:self.videoInputDevice];
   }
   if([self.captureSession canAddOutput:self.videoDataOutput]){
       [self.captureSession addOutput:self.videoDataOutput];
   }
   
   //?????????
   [self setVideoPreset];
   [self.captureSession commitConfiguration];
   //commit??????????????????????????????
   self.videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
   //????????????????????????
   self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
   
   //fps
   [self updateFps:25];
   //????????????
   [self setupPreviewLayer];
}

/**???????????????**/
- (void)setupPreviewLayer{
    self.preLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.preLayer.frame =  CGRectMake(0, 0, self.preLayerSize.width, self.preLayerSize.height);
    //????????????
    self.preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.preview.layer addSublayer:self.preLayer];
}


/**???????????????**/
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
    //????????????capture??????
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    //???????????????????????????????????????
    for (AVCaptureDevice *vDevice in videoDevices) {
        //???????????????????????????fps
        float maxRate = [(AVFrameRateRange *)[vDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0] maxFrameRate];
        //?????????????????????fps?????????????????????fps??????????????????
        if (maxRate >= fps) {
            //????????????fps?????????
            if ([vDevice lockForConfiguration:NULL]) {
                vDevice.activeVideoMinFrameDuration = CMTimeMake(10, (int)(fps * 10));
                vDevice.activeVideoMaxFrameDuration = vDevice.activeVideoMinFrameDuration;
                [vDevice unlockForConfiguration];
            }
        }
    }
}


#pragma mark-?????????
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
