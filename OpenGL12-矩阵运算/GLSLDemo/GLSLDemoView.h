//
//  GLSLDemoView.h
//  GLSLDemo
//
//  Created by AceDong on 2020/8/28.
//  Copyright © 2020 AceDong. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ChangeDirection) {
    ChangeDirectionNone,
    ChangeDirectionX,
    ChangeDirectionY,
    ChangeDirectionZ,
};

@interface GLSLDemoView : UIView

@property  (nonatomic,assign) CGFloat x;
@property  (nonatomic,assign) CGFloat y;
@property  (nonatomic,assign) CGFloat z;

@end

NS_ASSUME_NONNULL_END
