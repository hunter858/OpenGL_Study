//
//  CCView.h
//  001--GLSL
//
//  Created by CC老师 on 2017/12/16.
//  Copyright © 2017年 CC老师. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol CCViewDelegate <NSObject>
-(void)renderImage:(UIImage *)image;
@end

@interface CCView : UIView
@property (nonatomic,assign) id <CCViewDelegate> delegate;
@end
