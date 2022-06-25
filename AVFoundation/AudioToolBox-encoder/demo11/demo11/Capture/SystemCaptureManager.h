//
//  SystemCaptureManager.h
//  demo11
//
//  Created by pengchao on 2022/6/23.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

//捕获类型
typedef NS_ENUM(int,SystemCaptureType){
    SystemCaptureTypeVideo = 0,
    SystemCaptureTypeAudio,
    SystemCaptureTypeAll
};


@interface VideoConfig : NSObject

@property (nonatomic,assign) AVCaptureSessionPreset present;
@property (nonatomic,assign) NSInteger width;
@property (nonatomic,assign) NSInteger height;
@property (nonatomic,assign) NSInteger fps;
@property (nonatomic,assign) NSInteger bitRate;
+(instancetype)defaulConfig;
@end

@interface AudioConfig : NSObject
@property (nonatomic,assign) NSInteger sampleRate;
@property (nonatomic,assign) NSInteger channelCount;
@property (nonatomic,assign) NSInteger sampleSize;
@property (nonatomic,assign) NSInteger bitRate;
+(instancetype)defaulConfig;
@end



@protocol SystemCaptureManagerDelegate <NSObject>
@optional
- (void)captureSampleBuffer:(CMSampleBufferRef)sampleBuffer type:(SystemCaptureType)type;

@end

@interface SystemCaptureManager : NSObject

@property (nonatomic, strong) UIView *preview;
@property (nonatomic, assign, readonly) BOOL isRunning;
@property (nonatomic, weak) id<SystemCaptureManagerDelegate> delegate;
@property (nonatomic, assign, readonly) NSInteger width;
@property (nonatomic, assign, readonly) NSInteger height;

- (instancetype)initWithType:(SystemCaptureType)type videoConfig:(VideoConfig *)videoConfig audioConfig:(AudioConfig *)audioConfig;

- (void)prepareWithPreviewSize:(CGSize)size ;

+ (int)checkCameraAuthor ;

- (void)start;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
