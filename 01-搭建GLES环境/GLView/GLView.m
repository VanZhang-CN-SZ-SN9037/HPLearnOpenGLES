//
//  GLView.m
//  01-搭建GLES环境
//
//  Created by Van Zhang on 2024/3/21.
//

#import "GLView.h"
@import OpenGLES;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@interface GLView ()
@property (nonatomic, assign) GLsizei width;
@property (nonatomic, assign) GLsizei height;
@end
@implementation GLView
#pragma mark - Life Cycle
- (void)dealloc {
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }
    
    _eaglcontext = nil;
}
// Xib 创建View,走这个初始化
- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _width = CGRectGetWidth(frame);
        _height = CGRectGetHeight(frame);
        [self setup];
    }
    return self;
}
- (void)didMoveToWindow {
    [super didMoveToWindow];
    // 5.
    [self render];
}
#pragma mark - Override
// 想要显示 OpenGL 的内容, 需要把它缺省的 layer 设置为一个特殊的 layer(CAEAGLLayer).
+ (Class)layerClass {
//此处写你过期API相关的代码
    return [CAEAGLLayer class];
}

#pragma mark - Setup
- (void)setup {
    // 1、设定 layer 的类型。
    [self setupLayer];
    // 2、创建 OpenGL 上下文。
    [self setupContext];
    // 3、申请并绑定渲染缓冲区对象 RBO 用来存储即将绘制到屏幕上的图像数据。
    [self setupRenderBuffer];
    // 4、申请并绑定帧缓冲区对象 FBO。FBO 本身不能用于渲染，只有绑定了纹理（Texture）或者渲染缓冲区（RBO）等作为附件之后才能作为渲染目标。
    [self setupFrameBuffer];
    
    NSError *error;
    NSAssert1([self checkFramebuffer:&error], @"%@",error.userInfo[@"ErrorMessage"]);
}

- (void)setupLayer {
    // 用于显示的layer
    _eaglLayer = (CAEAGLLayer *)self.layer;
    
    //  CALayer默认是透明的，而透明的层对性能负荷很大。所以将其关闭。
    _eaglLayer.opaque = YES;
    _eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking: @(NO),
                                      kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
}

- (void)setupContext {
    if (!_eaglcontext) {
        // 创建GL环境上下文
        // EAGLContext 管理所有通过 OpenGL 进行 Draw 的信息.
        EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2; // 使用的 OpenGL API 的版本。
        _eaglcontext = [[EAGLContext alloc] initWithAPI:api];
    }
    
    NSAssert(_eaglcontext && [EAGLContext setCurrentContext:_eaglcontext], @"初始化GL环境失败");
}

- (void)setupRenderBuffer {
    // 释放旧的 renderbuffer
    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }
    
    // 生成renderbuffer ( renderbuffer = 用于展示的窗口 )
    glGenRenderbuffers(1, &_renderbuffer);// 创建 RBO。
    // 绑定renderbuffer
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);// 绑定 RBO 到 OpenGL 渲染管线。
    // GL_RENDERBUFFER 的内容存储到实现 EAGLDrawable 协议的 CAEAGLLayer
    [_eaglcontext renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];// 将渲染图层（_eaglLayer）的存储绑定到 RBO。
}

- (void)setupFrameBuffer {
    // 释放旧的 framebuffer
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    
    // 生成 framebuffer ( framebuffer = 画布 )
    glGenFramebuffers(1, &_framebuffer);// 创建 FBO。
    // 绑定 fraembuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);// 绑定 FBO 到 OpenGL 渲染管线。
    
    // framebuffer 不对绘制的内容做存储, 所以这一步是将 framebuffer 绑定到 renderbuffer ( 绘制的结果就存在 renderbuffer )
    // 将 RBO 绑定为 FBO 的一个附件，绑定后，OpenGL 对 FBO 的绘制会同步到 RBO 后再上屏。
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                              GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER,
                              _renderbuffer);
}

#pragma mark - Private
- (BOOL)checkFramebuffer:(NSError *__autoreleasing *)error {
    // 检查 framebuffer 是否创建成功
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSString *errorMessage = nil;
    BOOL result = NO;
    switch (status)
    {
        case GL_FRAMEBUFFER_UNSUPPORTED:
            errorMessage = @"framebuffer不支持该格式";
            result = NO;
            break;
        case GL_FRAMEBUFFER_COMPLETE:
#if DEBUG
            NSLog(@"framebuffer 创建成功");
#endif
            result = YES;
            break;
        case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
            errorMessage = @"Framebuffer不完整 缺失组件";
            result = NO;
            break;
        case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
            errorMessage = @"Framebuffer 不完整, 附加图片必须要指定大小";
            result = NO;
            break;
        default:
            // 一般是超出GL纹理的最大限制
            errorMessage = @"未知错误 error !!!!";
            result = NO;
            break;
    }
    
    NSLog(@"%@",errorMessage ? errorMessage : @"");
    *error = errorMessage ? [NSError errorWithDomain:@"com.colin.error"
                                                code:status
                                            userInfo:@{@"ErrorMessage" : errorMessage}] : nil;
    
    return result;
}

- (void)render {
    // 因为 GL 的所有 API 都是基于最后一次绑定的对象作为作用对象。有很多错误是因为没有绑定或者绑定了错误的对象导致得到了错误的结果。
    // 所以每次在修改 GL 对象时，先绑定一次要修改的对象。
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    // 5、清理窗口颜色，并设置渲染窗口。
    glClearColor(0, 1, 1, 1);// 设置渲染窗口颜色
    glClear(GL_COLOR_BUFFER_BIT);// 清空旧渲染缓存
    // 编写渲染相关的代码:
    // ...
    // 做完所有绘制操作后，最终呈现到屏幕上
    [_eaglcontext presentRenderbuffer:GL_RENDERBUFFER];
}

@end
#pragma clang diagnostic pop
