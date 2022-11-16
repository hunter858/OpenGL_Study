//
//  CCSystemCapture.m
//  001-Demo
//
//  Created by pengchao on 2019/2/16.
//

#import "CCSystemCapture.h"
#import "RenderView.h"
@interface CCSystemCapture ()<AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>

/********************控制相关**********/

//是否进行
@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, strong) AVCaptureMultiCamSession *captureSession;
@property (nonatomic, strong) dispatch_queue_t captureQueue;

@property (nonatomic, strong) AVCaptureDeviceInput *audioInputDevice;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;

/// utral camera
@property (nonatomic, strong) AVCaptureDeviceInput *dualDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dualVideoDataOutput;
@property (nonatomic, strong) AVCaptureConnection *dualVideoConnection;
@property (nonatomic, strong) RenderView *telephoneView;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *telephoneLayer;

/// utral camera
@property (nonatomic, strong) AVCaptureDeviceInput *ultraDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *ultraVideoDataOutput;
@property (nonatomic, strong) AVCaptureConnection *ultraVideoConnection;
@property (nonatomic, strong) RenderView *ultralView;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *ultralLayer;


/// utral camera
@property (nonatomic, strong) AVCaptureDeviceInput *angleDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *angleVideoDataOutput;
@property (nonatomic, strong) AVCaptureConnection *angleVideoConnection;
@property (nonatomic, strong) RenderView *angleView;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *angleLayer;


/// front camera
@property (nonatomic, strong) AVCaptureDeviceInput *frontDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *frontVideoDataOutput;
@property (nonatomic, strong) AVCaptureConnection *frontVideoConnection;
@property (nonatomic, strong) RenderView *frontView;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *frontLayer;


@property (nonatomic, assign) CGSize prelayerSize;

@end
@implementation CCSystemCapture{
    //捕捉类型
    CCSystemCaptureType capture;
}

- (instancetype)initWithType:(CCSystemCaptureType)type {
    self = [super init];
    if (self) {
        capture = type;
    }
    return self;
}

//准备捕获(视频/音频)
- (void)prepareWithPreviewSize:(CGSize)size {
    _prelayerSize = size;
    self.preview.frame = CGRectMake(0, 0, _prelayerSize.width, _prelayerSize.height);
    [self.preview layoutIfNeeded];
    if (capture == CCSystemCaptureTypeAudio) {
        [self setupAudio];
    } else if (capture == CCSystemCaptureTypeVideo) {
        [self setupVideo];
    } else if (capture == CCSystemCaptureTypeAll) {
        [self setupAudio];
        [self setupVideo];
    }
}

#pragma mark - Control start/stop capture or change camera
- (void)start{
    
    __weak typeof(self) weakSelf = self;
    if (!self.isRunning) {
        self.isRunning = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.captureSession startRunning];
        });
    }
}

- (void)stop{
    if (self.isRunning) {
        self.isRunning = NO;
        [self.captureSession stopRunning];
    }
    
}

#pragma mark-init Audio/video
- (void)setupAudio{
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

- (void)setupVideo {
    [self.preview addSubview:self.telephoneView];
    [self.preview addSubview:self.ultralView];
    [self.preview addSubview:self.angleView];
    [self.preview addSubview:self.frontView];
    
    [self.captureSession beginConfiguration];
    [self setupTelephoneCamera];
    [self setupUtralCamera];
    [self setupAngleCamera];
    [self setupFrontCamera];
    [self.captureSession commitConfiguration];
    
    [self.telephoneView layoutSubviews];
    [self.ultralView layoutSubviews];
    [self.angleView layoutSubviews];
    [self.frontView layoutSubviews];
}




- (AVCaptureDevice *)_deviceWithPosition:(AVCaptureDevicePosition)position devicetype:(AVCaptureDeviceType)devicetype {
    NSArray *devices;
    if (@available(iOS 11.1, *)) {
        NSArray<AVCaptureDeviceType> *deviceTypes = @[devicetype];

        AVCaptureDeviceDiscoverySession *videoDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:position];
        devices = videoDeviceDiscoverySession.devices;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
#pragma clang diagnostic pop
    }

    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }

    return nil;
}


- (void)setupTelephoneCamera {
    /// 长焦摄像头
    AVCaptureDevice *device = [self _deviceWithPosition:AVCaptureDevicePositionBack devicetype:AVCaptureDeviceTypeBuiltInTelephotoCamera];
    if (!device) return;
        
    //前置摄像头
    self.dualDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if ([self.captureSession canAddInput:self.dualDeviceInput]) {
        [self.captureSession addInputWithNoConnections:self.dualDeviceInput];
    }
    
    //视频输出
    self.dualVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    if ([self.captureSession canAddOutput:self.dualVideoDataOutput]) {
        [self.captureSession addOutputWithNoConnections:self.dualVideoDataOutput];
    }

    NSArray<AVCaptureInputPort *> *ports =  [self.dualDeviceInput portsWithMediaType:AVMediaTypeVideo sourceDeviceType:device.deviceType sourceDevicePosition:device.position];
    self.dualVideoConnection = [AVCaptureConnection connectionWithInputPorts:ports output:self.dualVideoDataOutput];
    self.dualVideoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    if ([self.captureSession canAddConnection:self.dualVideoConnection]) {
        [self.captureSession addConnection:self.dualVideoConnection];
    }
    
    AVCaptureVideoPreviewLayer *layer = self.telephoneLayer;
    [layer setSessionWithNoConnection:self.captureSession];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.telephoneView.layer addSublayer:layer];
    
    AVCaptureConnection *layerConnection = [AVCaptureConnection connectionWithInputPort:ports.firstObject videoPreviewLayer:self.telephoneLayer];
    if ([self.captureSession canAddConnection:layerConnection]) {
        [self.captureSession addConnection:layerConnection];
    }
}


- (void)setupUtralCamera {
    /// 广角相机
    AVCaptureDevice *device = [self _deviceWithPosition:AVCaptureDevicePositionBack devicetype:AVCaptureDeviceTypeBuiltInUltraWideCamera];
    if (!device) return;
    self.ultraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if ([self.captureSession canAddInput:self.ultraDeviceInput]) {
        [self.captureSession addInputWithNoConnections:self.ultraDeviceInput];
    }
    
    self.ultraVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    if ([self.captureSession canAddOutput:self.ultraVideoDataOutput]) {
        [self.captureSession addOutputWithNoConnections:self.ultraVideoDataOutput];
    }
    
    NSArray<AVCaptureInputPort *> *ports =  [self.ultraDeviceInput portsWithMediaType:AVMediaTypeVideo sourceDeviceType:device.deviceType sourceDevicePosition:device.position];
    self.ultraVideoConnection = [AVCaptureConnection connectionWithInputPorts:ports output:self.ultraVideoDataOutput];
    self.ultraVideoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    self.ultraVideoConnection.automaticallyAdjustsVideoMirroring = NO;
    if ([self.captureSession canAddConnection:self.ultraVideoConnection]) {
        [self.captureSession addConnection:self.ultraVideoConnection];
    }
    
    AVCaptureVideoPreviewLayer *layer = self.ultralLayer;
    [layer setSessionWithNoConnection:self.captureSession];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.ultralView.layer addSublayer:layer];
    AVCaptureConnection *layerConnection = [AVCaptureConnection connectionWithInputPort:ports.firstObject videoPreviewLayer:self.ultralLayer];
    if ([self.captureSession canAddConnection:layerConnection]) {
        [self.captureSession addConnection:layerConnection];
    }

    
}

- (void)setupAngleCamera {
    /// 主摄像头
    AVCaptureDevice *device = [self _deviceWithPosition:AVCaptureDevicePositionBack devicetype:AVCaptureDeviceTypeBuiltInWideAngleCamera];
    if (!device) return;
    self.angleDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if ([self.captureSession canAddInput:self.angleDeviceInput]) {
        [self.captureSession addInputWithNoConnections:self.angleDeviceInput];
    }
    
    self.angleVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];

    NSArray<AVCaptureInputPort *> *ports =  [self.angleDeviceInput portsWithMediaType:AVMediaTypeVideo sourceDeviceType:device.deviceType sourceDevicePosition:device.position];
    
    self.angleVideoConnection = [AVCaptureConnection connectionWithInputPorts:ports output:self.angleVideoDataOutput];
    self.angleVideoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    self.angleVideoConnection.automaticallyAdjustsVideoMirroring = NO;
    

    if ([self.captureSession canAddConnection:self.angleVideoConnection]) {
        [self.captureSession addConnection:self.angleVideoConnection];
    }

    /// add layer Connection
    AVCaptureVideoPreviewLayer *layer = self.angleLayer;
    [layer setSessionWithNoConnection:self.captureSession];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.angleView.layer addSublayer:layer];
    AVCaptureConnection *layerConnection = [AVCaptureConnection connectionWithInputPort:ports.firstObject videoPreviewLayer:self.angleLayer];
    if ([self.captureSession canAddConnection:layerConnection]) {
        [self.captureSession addConnection:layerConnection];
    }
}


- (void)setupFrontCamera {
    /// 前置摄像头
    AVCaptureDevice *device = [self _deviceWithPosition:AVCaptureDevicePositionFront devicetype:AVCaptureDeviceTypeBuiltInWideAngleCamera];
    //NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //AVCaptureDevice *device = videoDevices.lastObject;
    if (!device) return;
    self.frontDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    if ([self.captureSession canAddInput:self.frontDeviceInput]) {
        [self.captureSession addInputWithNoConnections:self.frontDeviceInput];
    }

    //视频输出
    self.frontVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    NSArray<AVCaptureInputPort *> *ports =  [self.frontDeviceInput portsWithMediaType:AVMediaTypeVideo sourceDeviceType:device.deviceType sourceDevicePosition:device.position];
    
    self.frontVideoConnection = [AVCaptureConnection connectionWithInputPorts:ports output:self.frontVideoDataOutput];
    self.frontVideoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    self.frontVideoConnection.automaticallyAdjustsVideoMirroring = NO;
//    self.frontVideoConnection.videoMirrored = NO;
    
    if ([self.captureSession canAddConnection:self.frontVideoConnection]) {
        [self.captureSession addConnection:self.frontVideoConnection];
    }
    
    /// add layer Connection
    AVCaptureVideoPreviewLayer *layer = self.frontLayer;
    [layer setSessionWithNoConnection:self.captureSession];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.frontView.layer addSublayer:layer];
    AVCaptureConnection *layerConnection = [AVCaptureConnection connectionWithInputPort:ports.firstObject videoPreviewLayer:self.frontLayer];

    if ([self.captureSession canAddConnection:layerConnection]) {
        [self.captureSession addConnection:layerConnection];
    }
}

/**设置分辨率**/
- (void)setVideoPreset {
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080])  {
        self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
        _witdh = 1080; _height = 1920;
    }else if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        _witdh = 720; _height = 1280;
    }else{
        self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        _witdh = 480; _height = 640;
    }
}

- (void)updateFps:(NSInteger)fps {
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
/**设置预览层**/
- (void)layoutPreviewLayer:(AVCaptureVideoPreviewLayer *)layer {
    [layer setSessionWithNoConnection:self.captureSession];
    layer.videoGravity = AVLayerVideoGravityResizeAspect;
}

#pragma mark-懒加载
- (AVCaptureMultiCamSession *)captureSession {
    if (!_captureSession) {
        _captureSession = [[AVCaptureMultiCamSession alloc] init];
    }
    return _captureSession;
}

- (dispatch_queue_t)captureQueue {
    if (!_captureQueue) {
        _captureQueue = dispatch_queue_create("TMCapture Queue", NULL);
    }
    return _captureQueue;
}


- (RenderView *)telephoneView {
    if(!_telephoneView) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width/2.0;
        CGFloat height = [UIScreen mainScreen].bounds.size.height/2.0;
        _telephoneView  = [[RenderView alloc]initWithFrame:CGRectMake(0, 0, width, height)];
//        _telephoneView.backgroundColor = [UIColor yellowColor];
        [_telephoneView.layer addSublayer:self.telephoneLayer];
        _telephoneView.contentLabel.text = @"TelephotoCamera";
        _telephoneView.contentLabel.center = CGPointMake(width/2.0, height/2.0);
    }
    return _telephoneView;
}

- (RenderView *)ultralView {
    if(!_ultralView) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width/2.0;
        CGFloat height = [UIScreen mainScreen].bounds.size.height/2.0;
        _ultralView = [[RenderView alloc]initWithFrame:CGRectMake(width, 0, width, height)];
//        _ultralView.backgroundColor = [UIColor redColor];
        [_ultralView.layer addSublayer:self.ultralLayer];
        _ultralView.contentLabel.text = @"UltraWideCamera";
        _ultralView.contentLabel.center =  CGPointMake(width/2.0, height/2.0);
    }
  
    return _ultralView;
}

- (RenderView *)angleView {
    if(!_angleView) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width/2.0;
        CGFloat height = [UIScreen mainScreen].bounds.size.height/2.0;
        _angleView = [[RenderView alloc]initWithFrame:CGRectMake(0, height, width, height)];
//        _angleView.backgroundColor = [UIColor greenColor];
        [_angleView.layer addSublayer:self.angleLayer];
        _angleView.contentLabel.text = @"WideAngleCamera";
        _angleView.contentLabel.center =  CGPointMake(width/2.0, height/2.0);
    }
    return _angleView;
}

- (RenderView *)frontView {
    if(!_frontView) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width/2.0;
        CGFloat height = [UIScreen mainScreen].bounds.size.height/2.0;
        _frontView = [[RenderView alloc]initWithFrame:CGRectMake(width, height, width, height)];
//        _frontView.backgroundColor = [UIColor grayColor];
        [_frontView.layer addSublayer:self.frontLayer];
        _frontView.contentLabel.text = @"Front WideAngleCamera";
        _frontView.contentLabel.center = CGPointMake(width/2.0, height/2.0);
    }
    return _frontView;
}

- (AVCaptureVideoPreviewLayer *)telephoneLayer {
    if (!_telephoneLayer) {
        _telephoneLayer = [[AVCaptureVideoPreviewLayer alloc]init];
        _telephoneLayer.frame = self.telephoneView.bounds;
    }
    return _telephoneLayer;
}

- (AVCaptureVideoPreviewLayer *)ultralLayer {
    if (!_ultralLayer) {
        _ultralLayer = [[AVCaptureVideoPreviewLayer alloc]init];
        _ultralLayer.frame = self.ultralView.bounds;
    }
    return _ultralLayer;
}

- (AVCaptureVideoPreviewLayer *)angleLayer {
    if (!_angleLayer) {
        _angleLayer = [[AVCaptureVideoPreviewLayer alloc]init];
        _angleLayer.frame = self.angleView.bounds;
    }
    return _angleLayer;
}

- (AVCaptureVideoPreviewLayer *)frontLayer {
    if (!_frontLayer) {
        _frontLayer = [[AVCaptureVideoPreviewLayer alloc]init];
        _frontLayer.frame = self.frontView.bounds;
    }
    return _frontLayer;
}


- (UILabel *)labelWithText:(NSString *)content{
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 140, 40)];
    label.font = [UIFont systemFontOfSize:16];
    label.text = content;
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}



- (UIView *)preview {
    if (!_preview) {
        _preview = [[UIView alloc] init];
    }
    return _preview;
}


- (void)dealloc {
    NSLog(@"capture销毁。。。。");
    [self destroyCaptureSession];
}

#pragma mark-销毁会话
-(void) destroyCaptureSession{
//    if (self.captureSession) {
//        if (capture == CCSystemCaptureTypeAudio) {
//            [self.captureSession removeInput:self.audioInputDevice];
//            [self.captureSession removeOutput:self.audioDataOutput];
//        }else if (capture == CCSystemCaptureTypeVideo) {
//            [self.captureSession removeInput:self.videoInputDevice];
//            [self.captureSession removeOutput:self.videoDataOutput];
//        }else if (capture == CCSystemCaptureTypeAll) {
//            [self.captureSession removeInput:self.audioInputDevice];
//            [self.captureSession removeOutput:self.audioDataOutput];
//            [self.captureSession removeInput:self.videoInputDevice];
//            [self.captureSession removeOutput:self.videoDataOutput];
//        }
//    }
    self.captureSession = nil;
}

#pragma mark-输出代理
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (connection == self.audioConnection) {
        [_delegate captureSampleBuffer:sampleBuffer type:CCSystemCaptureTypeAudio];
    } else if (connection == self.ultraVideoConnection) {
        [_delegate captureSampleBuffer:sampleBuffer type:CCSystemCaptureTypeVideo];
    }
    else if (connection == self.dualVideoConnection) {
        [_delegate captureSampleBuffer:sampleBuffer type:CCSystemCaptureTypeVideo];
    }
    else if (connection == self.angleVideoConnection) {
        [_delegate captureSampleBuffer:sampleBuffer type:CCSystemCaptureTypeVideo];
    }
    else if (connection == self.frontVideoConnection) {
        [_delegate captureSampleBuffer:sampleBuffer type:CCSystemCaptureTypeVideo];
    }
    
}



#pragma mark-授权相关
/**
 *  麦克风授权
 *  0 ：未授权 1:已授权 -1：拒绝
 */
+ (int)checkMicrophoneAuthor{
    int result = 0;
    //麦克风
    AVAudioSessionRecordPermission permissionStatus = [[AVAudioSession sharedInstance] recordPermission];
    switch (permissionStatus) {
        case AVAudioSessionRecordPermissionUndetermined:
            //    请求授权
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            }];
            result = 0;
            break;
        case AVAudioSessionRecordPermissionDenied://拒绝
            result = -1;
            break;
        case AVAudioSessionRecordPermissionGranted://允许
            result = 1;
            break;
        default:
            break;
    }
    return result;
    
    
}
/**
 *  摄像头授权
 *  0 ：未授权 1:已授权 -1：拒绝
 */
+ (int)checkCameraAuthor{
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

-(int)test{
    int result = 0;
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (videoStatus) {
        case AVAuthorizationStatusNotDetermined://第一次
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
@end



