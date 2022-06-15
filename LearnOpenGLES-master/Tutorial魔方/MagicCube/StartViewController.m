//
//  StartViewController.m
//  MagicCube
//
//  Created by lihua liu on 12-9-11.
//  Copyright (c) 2012年 yinghuochong. All rights reserved.
//

#import "StartViewController.h"
#import "ViewController.h"
#define NUM_OF_TEXTURE 6

@interface StartViewController()
@property (nonatomic , strong) IBOutlet UITableView* tableView;

@end


@implementation StartViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    selectedRow = 0;
    
    self.tableView.backgroundColor = [UIColor clearColor];
    
    magicPicArray = [[NSMutableArray alloc] initWithCapacity:0];
    for (int i=0; i<NUM_OF_TEXTURE; i++) {
        [magicPicArray addObject:[NSString stringWithFormat:@"m%d",i+1]];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return magicPicArray.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellID = @"cellID";
    UITableViewCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 43);
        imageView.tag = 100;
        [cell addSubview:imageView];

    }
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:100];
    NSString *str = [NSString stringWithFormat:@"%@.png",[magicPicArray objectAtIndex:indexPath.row]];
    [imageView setImage:[UIImage imageNamed:str]];
    return cell;  
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    for (int i=0; i<magicPicArray.count; i++) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        UIImageView *imageView = (UIImageView *)[cell viewWithTag:100];
        NSString *str = [NSString stringWithFormat:@"%@.png",[magicPicArray objectAtIndex:i]];
        imageView.image =  [UIImage imageNamed:str];
    }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:100];
    NSString *str = [NSString stringWithFormat:@"%@2.png",[magicPicArray objectAtIndex:indexPath.row]];
    imageView.image =  [UIImage imageNamed:str];
    selectedRow = indexPath.row;
}



- (IBAction)startClick:(id)sender
{
     NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:[NSString stringWithFormat:@"%@1.png",[magicPicArray objectAtIndex:selectedRow]] forKey:@"texture"];
     ViewController *vc = [[ViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

@end
