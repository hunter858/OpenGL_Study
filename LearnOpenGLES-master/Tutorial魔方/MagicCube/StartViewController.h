//
//  StartViewController.h
//  MagicCube
//
//  Created by lihua liu on 12-9-11.
//  Copyright (c) 2012年 yinghuochong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StartViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>
{
    long selectedRow;
    NSMutableArray *magicPicArray;
    UIActivityIndicatorView *indicatorView;
}

@end
