//
//  ViewController.m
//  demo15
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
    
    NSData *_vps;
    NSData *_sps;
    NSData *_pps;
    
    VideoDecoder *_decoder;
}
@property (weak, nonatomic) IBOutlet UIImageView *ImageView;

@end
const uint8_t startCode4[4] = {0x000,0x00,0x00,0x01};
const uint8_t startCode3[3] = {0x000,0x00,0x01};

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

/// 判断是否是 00 00 00 01 \ 00 00 01
static BOOL isNaluStartCode(unsigned char *data) {
    BOOL isStartCode = (memcmp(data, startCode4, 4) == 0) || (memcmp(data, startCode3, 3) == 0);
    return isStartCode;
}

/// 获取startCode 长度
static int getNaluStartCodeLength(unsigned char *data) {
    BOOL isStartCode = (memcmp(data, startCode4, 4) == 0) || (memcmp(data, startCode3, 3) == 0);
    if (!isStartCode) return 0;
    int nalu_startcode_size = 0;
    if (memcmp(data, startCode4, 4) == 0) {
        nalu_startcode_size = sizeof(startCode4);
    } else if (memcmp(data, startCode3, 3) == 0) {
        nalu_startcode_size = sizeof(startCode3);
    } else {
        //do nothing
    }
    return nalu_startcode_size;
}



- (void)tick {
    
    dispatch_sync(_decodeQueue, ^{
        packetSize = 0;
        if (packetBuffer) {
            free(packetBuffer);
            packetBuffer = NULL;
        }
    
        BOOL isStartCode = isNaluStartCode(_inputBuffer);
        unsigned int nalu_startcode_size = getNaluStartCodeLength(_inputBuffer);
    
        if (isStartCode && (_inputSize > nalu_startcode_size)) {
            
            uint8_t *pStart = _inputBuffer + nalu_startcode_size;         //pStart 表示 NALU 的起始指针
            uint8_t *pEnd = _inputBuffer + _inputSize;                    //pEnd 表示 NALU 的末尾指针
            while (pStart != pEnd) {
                
                BOOL isNextStartCode  = isNaluStartCode(pStart);
                if (isNextStartCode) {
                    
                    packetSize = (pStart - _inputBuffer);
                    packetBuffer = malloc(packetSize);
                    memcpy(packetBuffer, _inputBuffer, packetSize); //复制packet内容到新的缓冲区
                    memmove(_inputBuffer, _inputBuffer + packetSize, _inputSize - packetSize); //把缓冲区前移
                    _inputSize -= packetSize;
                    
                    if (nalu_startcode_size == 3) {
                    /// 额外处理 startCode == 00 00 01 情况
                        long newPacketSize = packetSize + 1;
                        uint8_t *newPacketBuffer = malloc(newPacketSize);
                        memset(newPacketBuffer, 0, sizeof(newPacketSize));
                        memcpy(newPacketBuffer + 1, packetBuffer , packetSize);
                        free(packetBuffer);
                        packetBuffer = newPacketBuffer;
                        packetSize = newPacketSize;
                        
                    }
                    break;
                }
                else {
                    ++pStart;
                }
            }
            
            if ((pStart == pEnd) && (_inputSize > sizeof(startCode4)) && (packetSize == 0)  && (packetBuffer == NULL)) {
                packetSize = _inputSize;//pStart - _inputBuffer - 3;
                packetBuffer = malloc(packetSize);
                memcpy(packetBuffer, _inputBuffer, packetSize);
                memmove(_inputBuffer, _inputBuffer + packetSize, _inputSize - packetSize); //把缓冲区前移
                _inputSize -= packetSize;
            }
            
        }
        if (packetBuffer == NULL || packetSize == 0) {
            [self endDecode];
            return;
        }
        //2.将packet的前4个字节换成大端的长度 （有可能startCode是 00000001 / 000001两种情况 都需要处理）
        uint32_t nalSize = (uint32_t)(packetSize - 4);
        uint8_t *pNalSize = (uint8_t*)(&nalSize);
        packetBuffer[0] = pNalSize[3];
        packetBuffer[1] = pNalSize[2];
        packetBuffer[2] = pNalSize[1];
        packetBuffer[3] = pNalSize[0];
       
        //3.判断帧类型（根据码流结构可知，startcode后面紧跟着就是码流的类型）
        int nalType = (packetBuffer[4] & 0x7E) >> 1;
        switch (nalType) {
            case 0x10:
            case 0x11:
            case 0x12:
            case 0x13:
            case 0x14:
            case 0x15:
                {
                    //IDR frame
                    [self _initDecodeSession];
                    [self decodePacket];
                }
                break;
            case 0x27:
                {
                    //SEI
                }
                break;
            case 0x20:
                {
                    //vps
                    if (_vps) { _vps = nil;}
                    size_t vpsSize = (size_t) packetSize - 4;
                    uint8_t *vps = malloc(vpsSize);
                    memcpy(vps, packetBuffer + 4, vpsSize);
                    _vps = [NSData dataWithBytes:vps length:vpsSize];
                    free(vps);
                }
                break;
            case 0x21:
                {
                    //sps
                    if (_sps) { _sps = nil;}
                    size_t spsSize = (size_t) packetSize - 4;
                    uint8_t *sps = malloc(spsSize);
                    memcpy(sps, packetBuffer + 4, spsSize);
                    _sps = [NSData dataWithBytes:sps length:spsSize];
                    free(sps);
                }
                break;
            case 0x22:
                {
                    //pps
                    if (_pps) { _pps = nil; }
                    size_t ppsSize = (size_t) packetSize - 4;
                    uint8_t *pps = malloc(ppsSize);
                    memcpy(pps, packetBuffer + 4, ppsSize);
                    _pps = [NSData dataWithBytes:pps length:ppsSize];
                    free(pps);
                }
                break;
            default:
                {
                    // B/P frame
                    [self decodePacket];
                }
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


- (void)_initDecodeSession {
    NSLog(@" initDecodeSession vps:%lu sps:%lu pps:%lu \n",_vps.length, _sps.length, _pps.length);
    if (!_vps || !_sps || !_pps) {
        NSLog(@"create decoder faid with lost sps or pps \n");
        return;
    }
    if (!_decoder) {
        _decoder = [[VideoDecoder alloc] initWithVps:_vps Sps:_sps pps:_pps];
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
    NSString *path = [[NSBundle mainBundle] pathForResource:@"main" ofType:@"h265"];
    _inputStream = [[NSInputStream alloc] initWithFileAtPath:path];
    [_inputStream open];
    
    _inputSize = 0;
    NSData *gopData = [NSData dataWithContentsOfFile:path];
    _inputMaxSize = gopData.length;
    
    if (_inputBuffer) {
        free(_inputBuffer);
        _inputBuffer = NULL;
    }
    _inputBuffer = malloc(_inputMaxSize);
    memcpy(_inputBuffer, gopData.bytes, gopData.length);
    _inputSize = _inputMaxSize;
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
