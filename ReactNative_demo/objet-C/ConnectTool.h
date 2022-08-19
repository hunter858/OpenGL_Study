//
//  ConnectTool.h
//  AwesomeProject
//
//  Created by pengchao on 2022/8/16.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@interface ConnectTools:NSObject <RCTBridgeModule>

@property (nonatomic,copy) NSString *name;
@property (nonatomic,assign) int value;

- (void)request:(NSDictionary *)params success:(RCTPromiseResolveBlock)success failed:(RCTPromiseRejectBlock)failed;

- (void)openView:(NSDictionary*)params;

@end

