//
//  HPGLProgram.m
//  03-视频渲染
//
//  Created by Van Zhang on 2024/3/21.
//

#import "HPGLProgram.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>

@interface HPGLProgram () {
    GLuint _glProgram;
    GLuint _glVertexShader;
    GLuint _glFragmentShader;
}

@end
@implementation HPGLProgram

- (instancetype)initWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader {
    self = [super init];
    if (self) {
        [self _createProgram:vertexShader fragmentSource:fragmentShader];
    }
    return self;
}

- (void)dealloc {
    if (_glVertexShader != 0) {
        glDeleteShader(_glVertexShader);
        _glVertexShader = 0;
    }

    if (_glFragmentShader != 0) {
        glDeleteShader(_glFragmentShader);
        _glFragmentShader = 0;
    }

    if (_glProgram != 0) {
        glDeleteProgram(_glProgram);
        _glProgram = 0;
    }
}

// 使用 GL 程序。
- (void)use {
    if (_glProgram != 0) {
        // 把 着色器程序 链接 到 渲染管线
        glUseProgram(_glProgram);
    }
}

// 根据名字获取 uniform 位置值
- (int)getUniformLocation:(NSString *)name {
    return glGetUniformLocation(_glProgram, [name UTF8String]);
}

// 根据名字获取 attribute 位置值
- (int)getAttribLocation:(NSString *)name {
    return glGetAttribLocation(_glProgram, [name UTF8String]);
}

// 加载和编译 shader，并链接 GL 程序。
- (void)_createProgram:(NSString *)vertexSource fragmentSource:(NSString *)fragmentSource {
    _glVertexShader = [self _loadShader:GL_VERTEX_SHADER source:vertexSource];
    _glFragmentShader = [self _loadShader:GL_FRAGMENT_SHADER source:fragmentSource];

    if (_glVertexShader != 0 && _glFragmentShader != 0) {
        if (_glProgram) {
            glDeleteProgram(_glProgram);
            _glProgram = 0;
        }
        _glProgram = glCreateProgram();
        glAttachShader(_glProgram, _glVertexShader);
        glAttachShader(_glProgram, _glFragmentShader);

        glLinkProgram(_glProgram);
        GLint linkStatus;
        glGetProgramiv(_glProgram, GL_LINK_STATUS, &linkStatus);
        if (linkStatus != GL_TRUE) {
            glDeleteProgram(_glProgram);
            _glProgram = 0;
        }
        
        glDeleteShader(_glVertexShader);
        glDeleteShader(_glFragmentShader);
    }
}

// 加载和编译 shader(着色器)。
- (GLuint)_loadShader:(int)shaderType source:(NSString *)source {
    int shader = glCreateShader(shaderType);
    const GLchar *cSource = (GLchar *) [source UTF8String];
    glShaderSource(shader,1, &cSource,NULL);
    glCompileShader(shader);

    GLint compiled;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    if (compiled != GL_TRUE) {
        glDeleteShader(shader);
        shader = 0;
    }

    return shader;
}

@end

#pragma clang diagnostic pop
