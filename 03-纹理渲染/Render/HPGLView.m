//
//  HPGLView.m
//  01-搭建GLES环境
//
//  Created by Van Zhang on 2024/3/21.
//

#import "HPGLView.h"
@import OpenGLES;

// 定义顶点的数据结构:包括顶点坐标和颜色维度。
#define PositionDimension 4
#define ColorDimension 4
#define textureDimension 2
typedef struct
{
    float position[PositionDimension]; // { x, y, z , w},w默认设置成1即可 4*4矩阵
    float color[ColorDimension]; // {r, g, b, a}
} CustomVertex;

typedef struct
{
    float position[PositionDimension]; // { x, y, z , w},w默认设置成1即可 4*4矩阵
    float texture[textureDimension]; // {u, v},纹理坐标系,坐标
} SenceVertex;
enum
{
    ATTRIBUTE_POSITION = 0,
    ATTRIBUTE_COLOR,
    ATTRIBUTE_TEXTURECoords,
    NUM_ATTRIBUTES
};
enum
{
    UNIFORM_TEXTURE = 0,
    NUM_UNIFORMS
};

GLint glViewAttributes [NUM_ATTRIBUTES];
GLint glViewUniforms [NUM_UNIFORMS];

// 7、根据三角形顶点信息申请顶点缓冲区对象 VBO 和拷贝顶点数据。
// 设置三角形 3 个顶点数据，包括坐标信息和颜色信息。
//static const CustomVertex vertices[] =
//{
//    { .position = { -1.0,  1.0, 0, 1 }, .color = { 1, 0, 0, 1 } },
//    { .position = { -1.0, -1.0, 0, 1 }, .color = { 0, 1, 0, 1 } },
//    { .position = {  1.0, -1.0, 0, 1 }, .color = { 0, 0, 1, 1 } }
//};
static const SenceVertex vertices[] =
{
    { .position = { -1.0,  1.0, 0, 1 }, .texture = {0, 1} },// 左上角
    { .position = { -1.0, -1.0, 0, 1 }, .texture = {0, 0} }, // 左下角
    { .position = { 1.0, 1.0, 0, 1 }, .texture = {1, 1} },// 右上角
    { .position = {  1.0, -1.0, 0, 1 }, .texture = {1, 0} }// 右下角
};

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@interface HPGLView ()
@property (nonatomic, assign) GLsizei width;
@property (nonatomic, assign) GLsizei height;
// 着色器程序
@property (nonatomic, assign) GLuint shaderProgram;
@end
@implementation HPGLView
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
    // 7. 渲染
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
    // 5、做渲染工作之前,要先设置着色器
    [self useShadersProgram];
    // 6. 设置顶点数据 和 纹理数据
    [self setupVBOsAndTextureData];
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
//    glViewport(0, 0, _width, _height); // 设置渲染窗口区域。
    
    glViewport(0, 0, self.drawableWidth, self.drawableHeight); // 设置渲染窗口区域。
    // ... 渲染操作
    [self rendering];
    // ...
    // 做完所有绘制操作后，最终呈现到屏幕上
    // 把 Renderbuffer 的内容显示到窗口系统 (CAEAGLLayer) 中。
    [_eaglcontext presentRenderbuffer:GL_RENDERBUFFER];
    
    // 9、清理。
    glDisableVertexAttribArray(glViewAttributes[ATTRIBUTE_POSITION]); // 关闭顶点颜色属性通道。
    glDisableVertexAttribArray(glViewAttributes[ATTRIBUTE_TEXTURECoords]); // 关闭纹理坐标位置属性通道。
    glDisableVertexAttribArray(glViewUniforms[UNIFORM_TEXTURE]); // 关闭纹理Uniform属性通道。
    glBindBuffer(GL_ARRAY_BUFFER, 0); // 解绑 VBO。
    glBindFramebuffer(GL_FRAMEBUFFER, 0); // 解绑 FBO。
    glBindRenderbuffer(GL_RENDERBUFFER, 0); // 解绑 RBO。
}
// 在这写真正的渲染代码
- (void)rendering{
    
    // 8、渲染纹理。
    // 获取与 Shader 中对应的参数信息：
    // 然后使用 glGetAttribLocation，来获得着色器变量的入口，使之绑定起来
    // 获取与 Shader 中对应的参数信息：
    glViewAttributes[ATTRIBUTE_POSITION] = glGetAttribLocation(_shaderProgram, "v_Position");
    glViewAttributes[ATTRIBUTE_TEXTURECoords]  = glGetAttribLocation(_shaderProgram, "v_TextureCoords");
    glViewUniforms[UNIFORM_TEXTURE] = glGetUniformLocation(_shaderProgram, "f_Texture");// 注意 Uniform 类型的获取方式
//    然后，使用 glEnableVertexAttribArray ，以顶点属性值作为参数，【启用顶点属性】（顶点属性默认是禁用的）。
//    至此，顶点属性的绑定已经完成了，之后只需要在渲染的时候，为对应的顶点属性赋值即可
    glEnableVertexAttribArray(glViewAttributes[ATTRIBUTE_POSITION]);
    glEnableVertexAttribArray(glViewAttributes[ATTRIBUTE_TEXTURECoords]);

    // 使用VBO时，最后一个参数0为要获取参数在GL_ARRAY_BUFFER中的偏移量
    // 【关联顶点属性】位置属性
    glVertexAttribPointer(glViewAttributes[ATTRIBUTE_POSITION],// attribute 变量的下标，范围是 [0, GL_MAX_VERTEX_ATTRIBS - 1]。
                          PositionDimension,// 指顶点数组中，一个 attribute 元素变量的坐标分量是多少（如：position, 程序提供的就是 {x, y, z, w} 点就是 4 个坐标分量）。
                          GL_FLOAT, // 数据的类型。
                          GL_FALSE, // 是否进行数据类型转换。
                          sizeof(SenceVertex),// 每一个数据在内存中的偏移量，如果填 0 就是每一个数据紧紧相挨着。
                          (const GLvoid*) offsetof(SenceVertex, position));// // 数据的内存首地址。
    // 【关联顶点属性】颜色属性
    glVertexAttribPointer(glViewAttributes[ATTRIBUTE_TEXTURECoords],
                          textureDimension,
                          GL_FLOAT,
                          GL_FALSE,
                          sizeof(SenceVertex),
                          (const GLvoid*) offsetof(SenceVertex, texture));
    // 绘制所有图元。
    glDrawArrays(GL_TRIANGLE_STRIP, // 绘制的图元方式。
                 0, // 从第几个顶点下标开始绘制。
                 sizeof(vertices) / sizeof(vertices[0])); // 有多少个顶点下标需要绘制。
}

#pragma mark - Utility|着色器处理
///    1.)  加载着色器
- (GLuint)loadShaderWithVertexShader:(NSString *)vert fragmentShader:(NSString *)frag {
    GLuint verShader, fragShader;
    GLuint program = glCreateProgram(); // 创建 Shader Program 对象。
    
//    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
//    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    [self compileShader:&verShader type:GL_VERTEX_SHADER shader:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER shader:frag];
    
    // 装载 Vertex Shader 和 Fragment Shader。
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

///    2.)  编译着色器
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    [self compileShader:shader type:type shader:content];
}
- (void)compileShader:(GLuint *)shader type:(GLenum)type shader:(NSString *)shaderCodes {
    NSString *content = shaderCodes;
    const GLchar *source = (GLchar *) [content UTF8String];
    *shader = glCreateShader(type); // 创建一个着色器对象。
    glShaderSource(*shader, 1, &source, NULL); // 关联顶点、片元着色器的代码。
    glCompileShader(*shader); // 编译着色器代码。
    
    // 打印编译日志。
    GLint compileStatus;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &compileStatus);
    if (compileStatus == GL_FALSE) {
        GLint infoLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &infoLength);
        if (infoLength > 0) {
            GLchar *infoLog = malloc(sizeof(GLchar) * infoLength);
            glGetShaderInfoLog(*shader, infoLength, NULL, infoLog);
            NSLog(@"%s -> %s", (type == GL_VERTEX_SHADER) ? "vertex shader" : "fragment shader", infoLog);
            free(infoLog);
        }
    }
}
/// MARK: 着色器处理
///  用
NSString *const HPDefaultTextureVertexShader = SHADER_STRING
(
//    attribute vec4 position; // 通过 attribute 通道获取顶点信息。4 维向量。
//    attribute vec4 inputTextureCoordinate; // 通过 attribute 通道获取纹理坐标信息。4 维向量。
// 
//    varying vec2 textureCoordinate; // 用于 vertex shader 和 fragment shader 间传递纹理坐标。2 维向量。
// 
//    uniform mat4 mvpMatrix; // 通过 uniform 通道获取 mvp 矩阵信息。4x4 矩阵。
// 
//    void main()
//    {
//        gl_Position = mvpMatrix * position; // 根据 mvp 矩阵和顶点信息计算渲染管线最终要用的顶点信息。
//        textureCoordinate = inputTextureCoordinate.xy; // 将通过 attribute 通道获取的纹理坐标数据中的 2 维分量传给 fragment shader。
//    }
 
     attribute vec4 v_Position;
     attribute vec2 v_TextureCoords;
     varying vec2 TextureCoordsVarying;

     void main (void) {
         gl_Position = v_Position;
         TextureCoordsVarying = v_TextureCoords;
     }

);
NSString *const HPDefaultTextureFragmentShader = SHADER_STRING
(
//    attribute vec4 position; // 通过 attribute 通道获取顶点信息。4 维向量。
//    attribute vec4 inputTextureCoordinate; // 通过 attribute 通道获取纹理坐标信息。4 维向量。
// 
//    varying vec2 textureCoordinate; // 用于 vertex shader 和 fragment shader 间传递纹理坐标。2 维向量。
// 
//    uniform mat4 mvpMatrix; // 通过 uniform 通道获取 mvp 矩阵信息。4x4 矩阵。
// 
//    void main()
//    {
//        gl_Position = mvpMatrix * position; // 根据 mvp 矩阵和顶点信息计算渲染管线最终要用的顶点信息。
//        textureCoordinate = inputTextureCoordinate.xy; // 将通过 attribute 通道获取的纹理坐标数据中的 2 维分量传给 fragment shader。
//    }
//     varying lowp vec4 colorVarying;
//     void main(void) {
//         gl_FragColor = colorVarying;
//     }
     precision mediump float;

     uniform sampler2D f_Texture;
     varying vec2 TextureCoordsVarying;

     void main (void) {
         vec4 mask = texture2D(f_Texture, TextureCoordsVarying);
         gl_FragColor = vec4(mask.rgb, 1.0);
     }
);
- (void)useShadersProgram {
    // 5、加载和编译 shader，并链接到着色器程序。
    if (_shaderProgram) {
        glDeleteProgram(_shaderProgram);
        _shaderProgram = 0;
    }
    // 加载和编译 shader。
//    NSString *simpleVSH = [[NSBundle mainBundle] pathForResource:@"glesVertexShader" ofType:@"vsh"];
//    NSString *simpleFSH = [[NSBundle mainBundle] pathForResource:@"glesFragementShader" ofType:@"fsh"];
    // 通过 全局常量的字符串形式,保存 着色器
    NSString *simpleVSH = HPDefaultTextureVertexShader;
    NSString *simpleFSH = HPDefaultTextureFragmentShader;
    _shaderProgram = [self loadShaderWithVertexShader:simpleVSH fragmentShader:simpleFSH];
    // 链接 shader program。
    glLinkProgram(_shaderProgram);
    // 打印链接日志。
    GLint linkStatus;
    glGetProgramiv(_shaderProgram, GL_LINK_STATUS, &linkStatus);
    if (linkStatus == GL_FALSE) {
        GLint infoLength;
        glGetProgramiv(_shaderProgram, GL_INFO_LOG_LENGTH, &infoLength);
        if (infoLength > 0) {
            GLchar *infoLog = malloc(sizeof(GLchar) * infoLength);
            glGetProgramInfoLog(_shaderProgram, infoLength, NULL, infoLog);
            NSLog(@"%s", infoLog);
            free(infoLog);
        }
    }
    // 加载着色器程序到 渲染管线
    glUseProgram(_shaderProgram);
}

- (void)setupVBOsAndTextureData {
    // 申请并绑定 VBO。
    // VBO 的作用是在显存中提前开辟好一块内存，用于缓存顶点数据，从而避免每次绘制时的 CPU 与 GPU 之间的内存拷贝，可以提升渲染性能。
    GLuint vertexBufferID;
    glGenBuffers(1, &vertexBufferID); // 创建 VBO。
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferID); // 绑定 VBO 到 OpenGL 渲染管线。
    // 将顶点数据 (CPU 内存) 拷贝到 VBO（GPU 显存）。
    glBufferData(GL_ARRAY_BUFFER, // 缓存块类型。
                 sizeof(vertices), // 创建的缓存块尺寸。
                 vertices, // 要绑定的顶点数据。
                 GL_STATIC_DRAW); // 缓存块用途。
    
    
    
    // 读取纹理
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"sample.jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    GLuint textureID = [self createTextureFromImage:image];
    // 将纹理 ID 传给着色器程序
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glUniform1i(glViewUniforms[UNIFORM_TEXTURE], 0);  // 将 textureSlot 赋值为 0，而 0 与 GL_TEXTURE0 对应，这里如果写 1，上面也要改成 GL_TEXTURE1
    
}
// 图片转纹理
- (GLuint)createTextureFromImage:(UIImage *)image {
    // 将 UIImage 转换为 CGImageRef
    CGImageRef cgImageRef = [image CGImage];
    GLuint width = (GLuint)CGImageGetWidth(cgImageRef);
    GLuint height = (GLuint)CGImageGetHeight(cgImageRef);
    CGRect rect = CGRectMake(0, 0, width, height);
    
    // 绘制图片
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    void *imageData = malloc(width * height * 4);
    CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGColorSpaceRelease(colorSpace);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, cgImageRef);

    // 生成纹理
    GLuint textureID;
    glGenTextures(1, &textureID);
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, imageData); // 将图片数据写入纹理缓存
    
    // 设置如何把纹素映射成像素
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    // 解绑
    glBindTexture(GL_TEXTURE_2D, 0);
    
    // 释放内存
    CGContextRelease(context);
    free(imageData);
    
    return textureID;
}

// 获取渲染缓存宽度
- (GLint)drawableWidth {
    GLint backingWidth;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    
    return backingWidth;
}

// 获取渲染缓存高度
- (GLint)drawableHeight {
    GLint backingHeight;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    
    return backingHeight;
}
@end
#pragma clang diagnostic pop
