//
//  GLView.h
//  01-搭建GLES环境
//
//  Created by Van Zhang on 2024/3/21.
//

#import <UIKit/UIKit.h>
// 苹果为了推广Metal,而把GLES 相关的类和API设置成过期,因此加这个预处理指令来屏蔽
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@interface GLView : UIView {
    CAEAGLLayer *_eaglLayer;
    EAGLContext *_eaglcontext;
    GLuint       _framebuffer;
    GLuint       _renderbuffer;
}

@end
#pragma clang diagnostic pop


