//
//  ConnectTool.m
//  AwesomeProject
//
//  Created by pengchao on 2022/8/16.
//

#import "ConnectTool.h"

@interface ConnectTools()

@property (nonatomic, strong) dispatch_source_t timer;
@end

@implementation ConnectTools

//导出桥接模块, 参数传空或者当前class的类名
//参数若为空, 默认模块名为当前class类名即AppEventMoudle
RCT_EXPORT_MODULE();


-(instancetype)init{
  self = [super init];
  if (self) {
    self.name = @"defult name pengchao";
    self.value = 99.0;
    self.value = 1;
  }
  return self;
}


// func1 导出一个异步方法

RCT_EXPORT_METHOD(openView:(NSDictionary*)params){
  // 因为是显示页面，所以让原生接口运行在主线程
     NSLog(@"start openView:");
     dispatch_async(dispatch_get_main_queue(), ^{
          sleep(3.0);
         // 在这里可以写需要原生处理的UI或者逻辑
         NSLog(@"end openView = %@", params);
     });
}


// func2 导出一个支持promis 的方法
RCT_EXPORT_METHOD(request2:(NSDictionary *)params success:(RCTPromiseResolveBlock)success failed:(RCTPromiseRejectBlock)failed){
  
  
 
  NSMutableDictionary *paramsMutable = @{@"result":@"success"}.mutableCopy;
  
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  __weak typeof(self) weakSelf = self;
  dispatch_async(queue, ^{
    [paramsMutable setValue:@(1) forKey:@"success"];
    sleep(1.0); //模拟网络请求
    if ((weakSelf.value % 2 == 0) && success != NULL) {
        success(paramsMutable);
     
    } else {
      NSError *error = [NSError errorWithDomain:@"我是Promise回调错误信息..." code:101 userInfo:nil];
      failed( @"-1",@"failed ",error);
    }
    weakSelf.value++;
  });
}

/// 导出一个同步方法
RCT_EXPORT_SYNCHRONOUS_TYPED_METHOD(NSArray *,testSyncFunc:(NSString *)name)
{
  NSMutableArray *events = @[@"value1",@"value2",@"value3",@"value4",@"value5"].mutableCopy;
  [events insertObject:name atIndex:0];
  return events.copy;
}


// fun4
// RCTResponseSenderBlock 是个数组，可以返回等多个参数 ,NSError 包裹在其中会被处理掉
RCT_EXPORT_METHOD(request:(NSString *)deviceName success:(RCTResponseSenderBlock)callBack)
{
  /// 无err的情况
  NSDictionary *response = @{@"key1":@"value1",
                             @"key3":@"value1",
  };
  
  
  NSError *error = [NSError errorWithDomain:@"errorDomain" code:-1 userInfo:@{@"key":@"value"}];
  callBack(@[error,response,@"value3"]);
  
  /// 有错误的情况
  
}


-(NSDictionary *)constDict{
  return @{@"key1":@"value1",
           @"key2":@"value2",
           @"key3":@"value3",
  };
}

///  调有回调的方法
//

- (void)startTimer {
  [self stopTimer];
  
  if (!self.timer) {
      dispatch_queue_t queue = dispatch_queue_create("test.tick.queue", DISPATCH_QUEUE_SERIAL);
      self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
      dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_USEC , 0);

      __weak typeof(self) weakSelf = self;
      dispatch_source_set_event_handler(self.timer, ^{
          __strong typeof(weakSelf) self = weakSelf;
          [self tick];
      });

      dispatch_resume(self.timer);
  }
}

-(void)tick {
  self.value ++;
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"valueChange" object:[NSNumber numberWithFloat:self.value]];
}

- (void)stopTimer{
  if (self.timer) {
      dispatch_source_cancel(self.timer);
      self.timer = NULL;
  }
}
  
  -(void)dealloc{
//    [NSNotificationCenter defaultCenter] removeObserver:<#(nonnull id)#>
  }

@end
