//
//  CCAudioDataQueue.h
//  001-Demo
//
//  Created by CC老师 on 2019/2/16.
//  Copyright © 2019年 CC老师. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CCAudioDataQueue : NSObject
@property (nonatomic, readonly) int count;

+(instancetype) shareInstance;

- (void)addData:(id)obj;

- (id)getData;
@end
