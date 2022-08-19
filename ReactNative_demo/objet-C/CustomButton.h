//
//  CustomButton.h
//  AwesomeProject
//
//  Created by pengchao on 2022/8/18.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <React/RCTViewManager.h>
#import "CustomButton.h"

/// 自定义VIew
@interface CustomButton : UIView
@property (nonatomic,copy) NSString *mapData;//RN 组件传来的属性
@property (nonatomic,copy) RCTBubblingEventBlock onButtonClick; //回调方法
@end

/// Bridger
@interface CustomButtonView : RCTViewManager
@end

