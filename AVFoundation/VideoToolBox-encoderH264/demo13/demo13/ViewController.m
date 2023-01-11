//
//  ViewController.m
//  demo13
//
//  Created by pengchao on 2022/6/23.
//

#import "ViewController.h"
#import "SystemCaptureManager.h"
#import "VideoEncoder.h"
#import "FileManager.h"


@interface ViewController () <SystemCaptureManagerDelegate,VideoEncoderDelegate>




@property (nonatomic, strong) SystemCaptureManager *sysCapture;
@property (nonatomic, strong) VideoEncoder *videoEncoder;
@property (nonatomic, strong) FileManager *fileManager;
@property (nonatomic, assign) FILE *h264_file;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [SystemCaptureManager checkCameraAuthor];
    UIButton *playButton = [self createButtonWithTitle:@"play" action:@selector(startAcion:)];
    UIButton *stopButton = [self createButtonWithTitle:@"stop" action:@selector(stopAction:)];
    
    CGFloat screenWith = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    playButton.frame = CGRectMake(screenWith - 100, 200, 100, 40);
    
    stopButton.frame = CGRectMake(screenWith - 100, 200 + 40 + 80, 100, 40);
    [self.view addSubview:playButton];
    [self.view addSubview:stopButton];
    
    
    
    
    // 1.初始化采集工具
    CGSize size = CGSizeMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    [self.sysCapture prepareWithPreviewSize:size];  //捕获视频时传入预览层大小
    self.sysCapture.preview.frame = CGRectMake(0, 100, size.width, size.height);
    [self.view addSubview:self.sysCapture.preview];
    self.sysCapture.delegate = self;
    
    // 2.音频编码器
    self.videoEncoder = [[VideoEncoder alloc]initWithConfig:[VideoConfig defaulConfig]];
    self.videoEncoder.delegate = self;


}


#pragma mark - SystemCaptureManager Delegate
-(void)captureSampleBuffer:(CMSampleBufferRef)sampleBuffer type:(SystemCaptureType)type {
    if (type == SystemCaptureTypeVideo) {
        //方法1
        [self.videoEncoder encodeYUVData:[self convertToYUVDataWithSampelBuffer:sampleBuffer]];
        
        //方法2
//        [self.videoEncoder encodeVideoSampleBuffer:sampleBuffer];
    }
}



-(NSData *)convertToYUVDataWithSampelBuffer:(CMSampleBufferRef)sampleBuffer{
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    //YUV 中Y 所占字节数（这里采集的数据源是YUV420f 所以参考 NV12结构）
    size_t Y_length = width * height;
    
    //YUV 中 UV 所占字节数 （4个YYYY分量共用一对UV 分量）
    size_t UV_length = (width *height) / 2;
    
    /// YUV 总长度
    size_t YUV420_length = Y_length + UV_length;
    
    uint8_t *YUV_frame = malloc(YUV420_length);
    // 0 通道对应Y 分量
    uint8_t *y_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(YUV_frame, y_frame, Y_length);
    
    // 1 通道对应sUV 分量
    uint8_t *uv_frame = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    memcpy(YUV_frame + Y_length, uv_frame,UV_length );
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    NSData *nv12_data = [NSData dataWithBytes:YUV_frame length:YUV420_length];
    free(YUV_frame);
    return nv12_data;
}


#pragma mark - AudioEncoder Delegate

-(void)videoEncodeCallback:(NSData *)naluData {
    if (naluData) {
        size_t nalu_length = fwrite(naluData.bytes, 1, naluData.length, self.h264_file);
        if (nalu_length != naluData.length) {
            NSLog( @"write NALU data error");
        }
        NSLog( @"write NALU lenght:%lu \n",nalu_length);
    }
}

- (void)videoEncodeCallbacksps:(NSData *)sps pps:(NSData *)pps {
    /// 这里的sps 和pps 都已经有了 起始码; 不用再加上，且文件必须先写 sps pps ，再写NALU
    if (sps && pps) {
        size_t sps_length = fwrite(sps.bytes, 1, sps.length, self.h264_file);
        if (sps_length != sps.length) {
            NSLog( @"write sps data error \n");
        }
        size_t pps_length = fwrite(pps.bytes, 1, pps.length, self.h264_file);
        if (sps_length != sps.length) {
            NSLog( @"write pps data error \n");
        }
        NSLog( @"write sps pps success \n");
    }
}



-(FILE *)h264_file {
    if (!_h264_file) {
        // 3.文件管理器 （写H264）
        self.fileManager = [[FileManager alloc]init];
        NSString *fileName =  [self.fileManager createRandomMediaTypeName:MEDIA_TYPE_H264];
        NSString *filePath = [self.fileManager createFileWithFileName:fileName];
        const char *h264File = filePath.UTF8String;
        FILE *h264_file = fopen(h264File, "wb");
        _h264_file = h264_file;
        NSLog(@"h264 file path %@",filePath);
    }
    return _h264_file;
}


- (SystemCaptureManager *)sysCapture{
    if (!_sysCapture) {
        _sysCapture  = [[SystemCaptureManager alloc] initWithType:SystemCaptureTypeVideo videoConfig:[VideoConfig defaulConfig] audioConfig:[AudioConfig defaulConfig]];
    }
    return  _sysCapture;
}


- (void)startAcion:(id)sender {
    
    if (!self.sysCapture.isRunning){
        [self.sysCapture start];
    }
}


- (void)stopAction:(id)sender {

    if (self.sysCapture.isRunning) {
        [self.sysCapture stop];
    }
}


#pragma mark private func

- (UIButton *)createButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button =[[UIButton alloc]init];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundColor:[UIColor orangeColor]];
    return button;
}



@end

