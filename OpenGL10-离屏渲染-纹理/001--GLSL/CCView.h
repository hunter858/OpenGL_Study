//
//  CCView.h
//  001--GLSL
//
//  Created by CC老师 on 2017/12/16.
//  Copyright © 2017年 CC老师. All rights reserved.
//

#import <UIKit/UIKit.h>



typedef void (^renderComplect)(UIImage *image);

@interface CCView : UIView

@property (nonatomic,assign) CGFloat roate_x;
@property (nonatomic,assign) CGFloat roate_y;
@property (nonatomic,assign) CGFloat roate_z;

@property (nonatomic,copy) renderComplect renderEndBlock;

- (void)renderLayer;


@end
