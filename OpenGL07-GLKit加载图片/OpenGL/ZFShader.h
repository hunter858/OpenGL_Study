//
//  ZFShader.h
//  OpenGL002
//
//  Created by 钟凡 on 2020/12/19.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZFShader : NSObject

@property (nonatomic, assign) GLuint programHandle;

- (id)initWithVertexShader:(NSString *)vertexShader
            fragmentShader:(NSString *)fragmentShader;
- (void)prepareToDraw;

@end

NS_ASSUME_NONNULL_END
