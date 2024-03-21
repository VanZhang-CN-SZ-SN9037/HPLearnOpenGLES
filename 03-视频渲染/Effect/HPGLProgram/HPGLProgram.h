//
//  HPGLProgram.h
//  03-视频渲染
//
//  Created by Van Zhang on 2024/3/21.
//

#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
// 封装了使用 GL 程序的部分 API
@interface HPGLProgram : NSObject
- (instancetype)initWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader;

- (void)use; // 使用 GL 程序
- (int)getUniformLocation:(NSString *)name; // 根据名字获取 uniform 位置值
- (int)getAttribLocation:(NSString *)name; // 根据名字获取 attribute 位置值
@end
#pragma clang diagnostic pop
