//
//  ViewController.m
//  demo17
//
//  Created by pengchao on 2022/6/30.
//

#import "ViewController.h"
#import "FileManager.h"
#import "test_rtmp.h"

uint32_t currentPostion = 0;

@interface ViewController ()
@property (nonatomic,strong) NSFileHandle *fileHandle;
@property (nonatomic,strong) NSString *flv_path;

@property (nonatomic,assign) FILE *flv_FILE;
@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self saveFileWithDocument];
}


-(void)saveFileWithDocument {
    
    FileManager *customFileManager = [[FileManager alloc]init];
    NSString *path = [customFileManager createFileWithFileName:@"push.flv"];
    FILE *flv_file = fopen(path.UTF8String, "wb");
    self.flv_path = path;
    self.flv_FILE = flv_file;
    
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"download" ofType:@"flv"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *attriDict = [fileManager attributesOfItemAtPath:resourcePath error:nil];
    
    
    self.fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    NSData *content = [NSData dataWithContentsOfFile:resourcePath];
    
    fwrite(content.bytes, content.length, 1, self.flv_FILE);

    content = nil;
    
}




- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
   int result = push_packet(self.flv_path.UTF8String, "rtmp://192.168.0.100:57139/railgun/test");
    
}





@end
