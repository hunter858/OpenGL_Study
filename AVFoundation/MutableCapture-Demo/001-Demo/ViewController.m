//
//  ViewController.m
//  001-Demo
//
//

#import "ViewController.h"
#import "CCSystemCapture.h"
#import "CCAVConfig.h"
@interface ViewController ()<CCSystemCaptureDelegate>

@property (nonatomic, strong) CCSystemCapture *capture;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    
    [self testVideo];
    
}

#pragma mark - Video Test
- (void)testVideo {

    [CCSystemCapture checkCameraAuthor];
    
    //捕获媒体
    _capture = [[CCSystemCapture alloc] initWithType:CCSystemCaptureTypeVideo];//这是我只捕获了视频
    [_capture prepareWithPreviewSize:self.view.bounds.size];  //捕获视频时传入预览层大小
    _capture.preview.frame = self.view.frame;
    [self.view addSubview:_capture.preview];
  
    self.capture.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.capture start];
}

@end
