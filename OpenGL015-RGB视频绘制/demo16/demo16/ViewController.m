//
//  ViewController.m
//  demo16
//
//  Created by pengchao on 2022/6/17.
//

#import "ViewController.h"
#import "RGBView.h"
#import "AVFoundation/AVFoundation.h"

@interface ViewController ()
{
    AVPlayer *_player;
    AVPlayerItemVideoOutput *_output;
    dispatch_source_t _timer;
    NSURL *_resourceURL;
}
@property (weak, nonatomic) IBOutlet UIButton *palyButton;
@property(nonatomic,strong) RGBView *renderView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initParams];
    [self initAction];
    self.renderView = [[RGBView alloc]initWithFrame:self.view.frame];
    [self.view addSubview:self.renderView];
    [self.view sendSubviewToBack:self.renderView];
}

- (void)initParams {
    
    /// 设置ItemVideoOutput 用于从AVPlayerItem 获取实时 的视频帧数据
    /// 这里视频帧的格式设置成 kCVPixelFormatType_420YpCbCr8BiPlanarFullRange 也就是YUV 420f
    NSDictionary *pixelBufferAttribute = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    AVPlayerItemVideoOutput *videoOutput = [[AVPlayerItemVideoOutput alloc]initWithPixelBufferAttributes:pixelBufferAttribute];
    _output = videoOutput;
    
    ///加载视频资源
    NSString *path = [[NSBundle mainBundle] pathForResource:@"download" ofType:@"mp4"];
    NSURL *pathURL = [NSURL fileURLWithPath:path];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:pathURL];
    [item addOutput:_output];
    _resourceURL = pathURL;

    /// 初始化播放器
    [self playWithItem:item];
    /// 开始播放、并起一个定时器用于获取当前视频帧
    [self playPlayer];
}

- (void)playWithItem:(AVPlayerItem *)item {
    if (!_player) {
        _player = [[AVPlayer alloc] initWithPlayerItem:item];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:item];
    } else {
        [_player replaceCurrentItemWithPlayerItem:item];
    }
}


- (void)initAction {
    
    [self.palyButton setTitle:@"play" forState:UIControlStateNormal];
    [self.palyButton addTarget:self action:@selector(playOrPaustAction:) forControlEvents:UIControlEventTouchUpInside];
}


- (void)startTimer {
    [self stoptimer];
    /// 每秒30帧
    NSUInteger FPS = 30;
    dispatch_queue_t _queue = dispatch_queue_create("com.render.statistics", NULL);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC));
    uint64_t interval = (uint64_t)(1.0/FPS * NSEC_PER_SEC);
    
    dispatch_source_set_timer(timer, start, interval, 0);
    
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(timer, ^{
        [weakSelf _tick];
    });
    dispatch_resume(timer);
    _timer = timer;
}

- (void)stoptimer {
    if (_timer) dispatch_source_cancel(_timer);
    _timer = nil;
}


- (CVPixelBufferRef)_copyTextureFromPlayItem:(AVPlayerItem *)item {
    AVPlayerItemVideoOutput *output = _output;
    
    AVAsset *asset = item.asset;
    CMTime time = item.currentTime;
    float offset = time.value * 1.0f / time.timescale;
    float frames = asset.duration.value * 1.0f / asset.duration.timescale;
    if (offset == frames) {
        [self pausePlayer];
        return NULL;
    }
    CVPixelBufferRef pixelBuffer = [output copyPixelBufferForItemTime:time itemTimeForDisplay:nil];
    return pixelBuffer;
}

- (void)_tick {
    AVPlayer *player = _player;
    CVPixelBufferRef pixelBuffer  = [self _copyTextureFromPlayItem:player.currentItem];
    /// 将获取到的 pixeBuffer 数据传到自定义的 YUVView 内绘制
    self.renderView.pixelBuffer = pixelBuffer;
    if (pixelBuffer) {
        CFRelease(pixelBuffer);
    }
}



- (void)_playerItemDidPlayToEndTime {
    if (_resourceURL) {
        AVPlayerItem *item = [AVPlayerItem playerItemWithURL:_resourceURL];
        _player = [[AVPlayer alloc] initWithPlayerItem:item];
    }
}


- (void)_playerItemDidPlayToEndTime:(NSNotification *)notification {
    [self pausePlayer];
}


- (void)playPlayer {
    [_player play];
    [self startTimer];
    [self updateButtonTitle:@"pause"];
}

- (void)pausePlayer {
    [_player pause];
    [self stoptimer];
    [self updateButtonTitle:@"play"];
}


- (void)playOrPaustAction:(UIButton *)button {
    if (button.selected) {
        [self pausePlayer];
        button.selected = NO;
    } else {
        [self playPlayer];
        button.selected = YES;
    }
}

- (void)updateButtonTitle:(NSString *)title {
    if (title) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.palyButton setTitle:title forState:UIControlStateNormal];
        });
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
}

@end
