//
//  ViewController.m
//  SkyBoxImage
//
//  Created by 林伟池 on 16/4/27.
//  Copyright © 2016年 林伟池. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic , strong) UIImageView* mImageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.mImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100 * 6)];
    UIImage* image = [UIImage imageNamed:@"skybox"];
    [self.mImageView setImage:image];
    NSLog(@"%@", [image description]);
    [self.view addSubview:self.mImageView];
    
    long length = image.size.width / 4;
    long indices[] = {
        length * 2, length, //right
        0, length, //left
        length, 0, //top
        length, length * 2, //bottom
        length, length, //front
        length * 3, length, //back
    };
    long facesCount = sizeof(indices)/sizeof(indices[0]) / 2;
    CGSize imageSize = {length, length * facesCount};
    UIGraphicsBeginImageContext(imageSize);
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextRotateCTM(context, M_PI); //先旋转180度，是按照原先顺时针方向旋转的。这个时候会发现位置偏移了
//    CGContextScaleCTM(context, -1, 1); //再水平旋转一下
//    CGContextTranslateCTM(context,0, -image.size.height);//再把偏移掉的位置调整回来

    
    for (int i = 0; i + 2 <= facesCount * 2; i += 2) {
        CGImageRef cgimage = CGImageCreateWithImageInRect(image.CGImage, CGRectMake(indices[i], indices[i + 1], length, length));
        UIImage* tmp = [UIImage imageWithCGImage:cgimage];
        [tmp drawInRect:CGRectMake(0, length * i / 2, length, length)];
        
// // // // // // // // // //
//        CGContextRef gc = UIGraphicsGetCurrentContext();
        //坐标系转换
        //因为CGContextDrawImage会使用Quartz内的以左下角为(0,0)的坐标系
//        CGContextTranslateCTM(gc, 0, length * facesCount);
//        CGContextScaleCTM(gc, 1, -1);
//        CGContextDrawImage(gc, CGRectMake(0, length * i / 2, length, length), cgimage);

    }
    UIImage* finalImage = UIGraphicsGetImageFromCurrentImageContext();
    [self.mImageView setImage:finalImage];
    NSLog(@"final %@", [finalImage description]);
    
    NSString *path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]stringByAppendingPathComponent:@"image.png"];
    NSLog(@"path:\n %@", path);
    if ([UIImagePNGRepresentation(finalImage) writeToFile:path atomically:YES]) {
        NSLog(@"SUCCESS");
    }
    else {
        NSLog(@"FAIL");
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
