//
//  ViewController.m
//  demo14
//
//  Created by pengchao on 2022/6/23.
//

#import "ViewController.h"
#import "VideoDecoder.h"

@interface ViewController () <VideoDecoderDelegate>
{
    CADisplayLink *_displayLink;
    
    dispatch_queue_t _decodeQueue;
    
    NSInputStream *_inputStream;
    
    
    //startcode  对应的内存起点位置
    uint8_t *_inputBuffer;
    
    long _inputSize;

    long _inputMaxSize;
    
    uint8_t *packetBuffer;
    long packetSize;
    
    NSData *_sps;
    NSData *_pps;
    
    VideoDecoder *_decoder;
}
@property (weak, nonatomic) IBOutlet UIImageView *ImageView;

@end
const uint8_t startCode[4] = {0x000,0x00,0x00,0x01};
const uint8_t startCode2[3] = {0x000,0x00,0x01};

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupUI];
    [self setupFunc];
}


- (void)setupUI {
    UIButton *playButton = [self createButtonWithTitle:@"encoder" action:@selector(startAcion:)];
    CGFloat screenWith = [UIScreen mainScreen].bounds.size.width;
    //CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    playButton.frame = CGRectMake(screenWith - 100, 200, 100, 40);
    [self.view addSubview:playButton];
}

- (void)setupFunc {
    _decodeQueue = dispatch_queue_create("www.serial.com", NULL);
    
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    displayLink.paused = true;
    displayLink.frameInterval  = 1;
    _displayLink = displayLink;
}


- (void)tick {
    
    dispatch_sync(_decodeQueue, ^{
        //1.获取packetBuffer和packetSize
        packetSize = 0;
        if (packetBuffer) {
            free(packetBuffer);
            packetBuffer = NULL;
        }
        if (_inputSize < _inputMaxSize && _inputStream.hasBytesAvailable) { //一般情况下只会执行一次,使得inputMaxSize等于inputSize
            _inputSize += [_inputStream read:_inputBuffer + _inputSize maxLength:_inputMaxSize - _inputSize];
        }
        if ((memcmp(_inputBuffer, startCode, 4) == 0) && (_inputSize > 4)) {
            
            uint8_t *pStart = _inputBuffer + 4;         //pStart 表示 NALU 的起始指针
            uint8_t *pEnd = _inputBuffer + _inputSize;  //pEnd 表示 NALU 的末尾指针
            while (pStart != pEnd) {                    //这里使用一种简略的方式来获取这一帧的长度：通过查找下一个0x00000001来确定。
                if(memcmp(pStart - 3, startCode, 4) == 0 ) {
                    packetSize = pStart - _inputBuffer - 3;
                    if (packetBuffer) {
                        free(packetBuffer);
                        packetBuffer = NULL;
                    }
                    packetBuffer = malloc(packetSize);
                    memcpy(packetBuffer, _inputBuffer, packetSize); //复制packet内容到新的缓冲区
                    memmove(_inputBuffer, _inputBuffer + packetSize, _inputSize - packetSize); //把缓冲区前移
                    _inputSize -= packetSize;
                    break;
                }
                else {
                    ++pStart;
                }
            }
        }
        if (packetBuffer == NULL || packetSize == 0) {
            [self endDecode];
            return;
        }
        
        //2.将packet的前4个字节换成大端的长度
        //大端：高字节保存在低地址
        //小端：高字节保存在高地址
        //大小端的转换实际上及时将字节顺序换一下即可
        uint32_t nalSize = (uint32_t)(packetSize - 4);
        uint8_t *pNalSize = (uint8_t*)(&nalSize);
        packetBuffer[0] = pNalSize[3];
        packetBuffer[1] = pNalSize[2];
        packetBuffer[2] = pNalSize[1];
        packetBuffer[3] = pNalSize[0];
        
        //3.判断帧类型（根据码流结构可知，startcode后面紧跟着就是码流的类型）
        int nalType = packetBuffer[4] & 0x1f;
        switch (nalType) {
            case 0x05:
                //IDR frame
                [self initDecodeSession];
                [self decodePacket];
                break;
            case 0x07:
                //sps
                if (_sps) { _sps = nil;}
                size_t spsSize = (size_t) packetSize - 4;
                uint8_t *sps = malloc(spsSize);
                memcpy(sps, packetBuffer+4, spsSize);
                _sps = [NSData dataWithBytes:sps length:spsSize];
                break;
            case 0x08:
                //pps
                if (_pps) { _pps = nil; }
                size_t ppsSize = (size_t) packetSize - 4;
                uint8_t *pps = malloc(ppsSize);
                memcpy(pps, packetBuffer+4, ppsSize);
                _pps = [NSData dataWithBytes:pps length:ppsSize];
                break;
            default:
                // B/P frame
                [self decodePacket];
                break;
        }
    });

}


- (void)endDecode {
    _displayLink.paused = true;
    [_inputStream close];
    NSLog(@"end encoder \n");
}


- (void)decodePacket {
    NSLog(@" decodePacket packetSize:%d",packetSize);
    NSData *packet = [NSData dataWithBytes:packetBuffer length:packetSize];
    [_decoder decoderWithData:packet];
}


- (void)initDecodeSession {
    NSLog(@" initDecodeSession sps:%ll pps:%ll \n",_sps.length,_pps.length);
    if (!_sps || !_pps) {
        NSLog(@"create decoder faid with lost sps or pps \n");
        return;
    }
    if (!_decoder) {
        _decoder = [[VideoDecoder alloc] initWithSps:_sps pps:_pps];
        _decoder.delegate = self;
    }
}


-(void)videoDecoderCallbackPixelBuffer:(UIImage *)pixeBuffer{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.ImageView.image = pixeBuffer;
    });
}


- (void)startAcion:(UIButton *)button {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"h264"];
    _inputStream = [[NSInputStream alloc] initWithFileAtPath:path];
    [_inputStream open];
    
    _inputSize = 0;
    _inputMaxSize = [NSData dataWithContentsOfFile:path].length;
    
    if (_inputBuffer) {
        free(_inputBuffer);
        _inputBuffer = NULL;
    }
    _inputBuffer = malloc(_inputMaxSize);

    _displayLink.paused = false;
    NSLog(@"start encoder \n");
}

- (UIButton *)createButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button =[[UIButton alloc]init];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundColor:[UIColor orangeColor]];
    return button;
}

@end
