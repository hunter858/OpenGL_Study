//
//  RenderView.m
//  001-Demo
//
//

#import "RenderView.h"

@implementation RenderView
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self){
        _contentLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, frame.size.width, 40)];
        _contentLabel.textAlignment = NSTextAlignmentCenter;
        _contentLabel.textColor  = [UIColor redColor];
        [self addSubview:_contentLabel];
        [self bringSubviewToFront:_contentLabel];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
}

@end
