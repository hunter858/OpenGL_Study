//
//  CustomButton.m
//  AwesomeProject
//
//  Created by pengchao on 2022/8/18.
//

#import "CustomButton.h"
@interface CustomButton()
@property (nonatomic,strong) UIButton *leftButton;
@property (nonatomic,strong) UIImageView  *rightImage;
@property (nonatomic,assign) NSUInteger value;
@end
@implementation CustomButton



- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self setupUI];
    self.value = 0;
  }
  return self;
}

- (void)setupUI {
  self.leftButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 60, 40)];
  [self.leftButton setTitle:@"custom" forState:UIControlStateNormal];
  [self.leftButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
  [self.leftButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
  self.rightImage = [[UIImageView alloc]initWithFrame:CGRectMake(60, 0, 40, 40)];
  self.rightImage.image =[UIImage imageNamed:@"test_icon"];
  
  [self.leftButton addTarget:self action:@selector(clickFunc:) forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:self.leftButton];
  [self addSubview:self.rightImage];
}

- (void)clickFunc:(UIButton *)sender {
  NSLog(@"clickFunc");
  self.value ++;
  // @{@"key":@(self.value) 这里表示需要回传给外部的值
  self.onButtonClick(@{@"key":@(self.value)});
}

//RN 部分的属性被赋值后会自动调用这个方法传参
-(void)setTitleName:(NSString *)titleName{
  if (titleName) {
    [self.leftButton setTitle:titleName forState:UIControlStateNormal];
  }
  [self layoutSubviews];
}

- (void)setMapData:(NSString *)mapData {
  NSLog(@"%@",mapData);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

@interface CustomButtonView ()
@property (nonatomic,strong) CustomButton *customBtn;
@end


@implementation CustomButtonView
RCT_EXPORT_MODULE();
// props 参数 (定义的参数要在相应的view实现方法)
RCT_EXPORT_VIEW_PROPERTY(titleName, NSString)

// 字典类型 ，参数名 mapData
RCT_EXPORT_VIEW_PROPERTY(mapData, NSDictionary)

// 点击事件
RCT_EXPORT_VIEW_PROPERTY(onButtonClick, RCTBubblingEventBlock)


RCT_CUSTOM_VIEW_PROPERTY(region, MKCoordinateRegion, CustomButtonView){
}

- (UIView *)view
{
  /// frame不设置也行，反正都会被覆盖
  if (!_customBtn) {
    _customBtn = [[CustomButton alloc]initWithFrame:CGRectZero];
  }
  return _customBtn;
}


@end
