//
//  OSCaptureView.m
//  OpenGL_draw_cube
//
//  Created by xu jie on 16/8/2.
//  Copyright © 2016年 xujie. All rights reserved.
//

#import "OSCaptureView.h"

@interface OSCaptureView()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property(nonatomic,strong)AVCaptureSession *captureSession;// 捕捉视图的会话对象
@property(nonatomic,strong)CALayer *previewLayer;// 显示视频的layer层
@property(nonatomic,strong)CIFilter *filter; // 滤波器
@property(nonatomic,strong)CIContext *context;
@end
@implementation OSCaptureView
-(CIContext *)context{
    if (_context){
        return _context;
    }
    EAGLContext *eagContext = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    NSDictionary *options = @{kCIContextWorkingColorSpace : [NSNull null]};
    return [CIContext contextWithEAGLContext:eagContext options:options];
}

-(void)setup:(Callback)callback{
    self.callback = callback;
    // 创建layer 层
    self.previewLayer = [CALayer layer];
    self.previewLayer.bounds = CGRectMake(0, 0, self.bounds.size.height, self.bounds.size.width);
    
    // 调整摄像头的位置
    self.previewLayer.position  =  CGPointMake(self.frame.size.width / 2.0, self.frame.size.height/2.0);
    [self.previewLayer setAffineTransform:CGAffineTransformMakeRotation(M_PI /  2.0)];
    [self.layer addSublayer:self.previewLayer];
    
    // 创建摄像会话层
    self.captureSession = [[AVCaptureSession alloc]init];
    [self.captureSession beginConfiguration];
    self.captureSession.sessionPreset = AVCaptureSessionPresetLow;
    AVCaptureDevice *capureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 设置输出
    AVCaptureInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:capureDevice error:nil];
    
    if ([self.captureSession canAddInput:deviceInput]){
        [self.captureSession addInput:deviceInput];
    }
    
    AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc]init];
    
//    dataOutput.videoSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey :[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]};
    dataOutput.alwaysDiscardsLateVideoFrames = YES;
    
    if ([self.captureSession canAddOutput:dataOutput]){
        [self.captureSession addOutput:dataOutput];
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    //dispatch_queue_t queue  = dispatch_get_main_queue();
    [dataOutput setSampleBufferDelegate:self queue:queue];
    [self.captureSession commitConfiguration];
    [self.captureSession startRunning];
    
}
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
 
    CIImage *ciimage = [CIImage imageWithCVPixelBuffer:imageBuffer];
        CGImageRef imageRef = [self.context createCGImage:ciimage fromRect:ciimage.extent];

    dispatch_async(dispatch_get_main_queue(), ^{
    self.previewLayer.contents = (__bridge id _Nullable)(imageRef);}
    );
    
    
}




@end
