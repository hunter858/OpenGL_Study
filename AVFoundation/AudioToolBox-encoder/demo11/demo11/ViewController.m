//
//  ViewController.m
//  demo11
//
//  Created by pengchao on 2022/6/23.
//

#import "ViewController.h"
#import "SystemCaptureManager.h"
#import "AudioEncoder.h"
#import "FileManager.h"


@interface ViewController () <SystemCaptureManagerDelegate,AudioEncoderDelegate>




@property (nonatomic, strong) SystemCaptureManager *sysCapture;
@property (nonatomic, strong) AudioEncoder *audioEncoder;
@property (nonatomic, strong) FileManager *fileManager;
@property (nonatomic, assign) FILE *aac_file;

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
    self.audioEncoder = [[AudioEncoder alloc]initWithConfig:[AudioConfig defaulConfig]];
    self.audioEncoder.delegate = self;

}


#pragma mark - SystemCaptureManager Delegate
-(void)captureSampleBuffer:(CMSampleBufferRef)sampleBuffer type:(SystemCaptureType)type {
    if (type == SystemCaptureTypeAudio) {
       
        // 方法 1
        [self.audioEncoder encodeAudioSampleBuffer:sampleBuffer];
        
        // 方法 2
        //[self.audioEncoder encodeAudioData:[self convertPCMWithSampleBuffer:sampleBuffer]];
    }
}



-(NSData *)convertPCMWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    //获取音频数据大小
    NSUInteger pcmBufferSize = CMSampleBufferGetTotalSampleSize(sampleBuffer);
    //分配内存
    int8_t *pcmBuffer = alloca((int32_t)pcmBufferSize);
    //获取音频数据
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);

    OSStatus status = CMBlockBufferCopyDataBytes(blockBuffer, 0, pcmBufferSize, pcmBuffer);
    if (status != kCMBlockBufferNoErr) {
        NSLog(@"copy blcok buffer error \n");
    }
    //将_pcmBufferSize数据set到pcmBuffer中.
    NSData *pcmData = [NSData dataWithBytes:pcmBuffer length:pcmBufferSize];
    return pcmData;
}


#pragma mark - AudioEncoder Delegate

- (void)audioEncodeCallback:(NSData *)aacData{
    if(aacData.length) {
        NSData *adts_header = [self.audioEncoder ADTSHeaderWithLength:(NSUInteger)aacData.length];
        NSLog(@"xxx write header %lu",adts_header.length);
        //文件写ADTS header
        size_t headerLength = fwrite(adts_header.bytes, 1, adts_header.length, self.aac_file);
        if (headerLength != adts_header.length ) {
            NSLog(@"write adts heder error");
        }
        // AAC 数据部分 写入文件
        size_t aacLength = fwrite(aacData.bytes, 1, aacData.length, self.aac_file);
        NSLog(@"xxx write aac %lu",aacData.length);
        if (aacLength != aacData.length ) {
            NSLog(@"write aac data error");
        }
    }
}

- (SystemCaptureManager *)sysCapture{
    if (!_sysCapture) {
        _sysCapture  = [[SystemCaptureManager alloc]initWithType:SystemCaptureTypeAudio videoConfig:[VideoConfig defaulConfig] audioConfig:[AudioConfig defaulConfig]];
    }
    return  _sysCapture;
}


- (UIButton *)createButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button =[[UIButton alloc]init];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundColor:[UIColor orangeColor]];
    return button;
}


- (void)startAcion:(id)sender {
    
    if (!self.sysCapture.isRunning){
        [self.sysCapture start];
        [self.audioEncoder start];
    }
}


- (void)stopAction:(id)sender {

    if (self.sysCapture.isRunning) {
        [self.sysCapture stop];
        [self.audioEncoder stop];
    }
}


- (FILE *)aac_file {
    if (!_aac_file){
        self.fileManager = [[FileManager alloc] init];
        NSString *aacFileName =  [self.fileManager createRandomMediaTypeName:MEDIA_TYPE_AAC];
        NSString *audioFilePath = [self.fileManager createFileWithFileName:aacFileName];
        const char *audioFile = audioFilePath.UTF8String;
        FILE *aac_file = fopen(audioFile, "wb");
        _aac_file = aac_file;
        NSLog(@"aac file path %@",audioFilePath);
    }
    return _aac_file;
        
}




@end
