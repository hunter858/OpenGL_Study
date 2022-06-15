//
//  CCAudioDataQueue.m
//  001-Demo
//
//  Created by CC老师 on 2019/2/16.
//  Copyright © 2019年 CC老师. All rights reserved.
//

#import "CCAudioDataQueue.h"

@interface CCAudioDataQueue ()
@property (nonatomic, strong) NSMutableArray *bufferArray;
@end

@implementation CCAudioDataQueue
@synthesize count;
static CCAudioDataQueue *_instance = nil;

+(instancetype) shareInstance
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    }) ;
    return _instance ;
}

- (instancetype)init{
    if (self = [super init]) {
        _bufferArray = [NSMutableArray array];
        count = 0;
    }
    return self;
}

-(void)addData:(id)obj{
    @synchronized (_bufferArray) {
        [_bufferArray addObject:obj];
        count = (int)_bufferArray.count;
    }
}

- (id)getData{
    @synchronized (_bufferArray) {
        id obj = nil;
        if (count) {
            obj = [_bufferArray firstObject];
            [_bufferArray removeObject:obj];
            count = (int)_bufferArray.count;
        }
        return obj;
    }
}
@end
