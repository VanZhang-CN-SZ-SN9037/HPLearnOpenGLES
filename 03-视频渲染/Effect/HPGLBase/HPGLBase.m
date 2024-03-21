//
//  HPGLBase.m
//  03-视频渲染
//
//  Created by Van Zhang on 2024/3/21.
//

#import "HPGLBase.h"

NSString *const HPDefaultVertexShader = SHADER_STRING
(
    attribute vec4 position; // 通过 attribute 通道获取顶点信息。4 维向量。
    attribute vec4 inputTextureCoordinate; // 通过 attribute 通道获取纹理坐标信息。4 维向量。
 
    varying vec2 textureCoordinate; // 用于 vertex shader 和 fragment shader 间传递纹理坐标。2 维向量。
 
    uniform mat4 mvpMatrix; // 通过 uniform 通道获取 mvp 矩阵信息。4x4 矩阵。
 
    void main()
    {
        gl_Position = mvpMatrix * position; // 根据 mvp 矩阵和顶点信息计算渲染管线最终要用的顶点信息。
        textureCoordinate = inputTextureCoordinate.xy; // 将通过 attribute 通道获取的纹理坐标数据中的 2 维分量传给 fragment shader。
    }
);

NSString *const HPDefaultFragmentShader = SHADER_STRING
(
    varying highp vec2 textureCoordinate; // 从 vertex shader 传递来的纹理坐标。
    uniform sampler2D inputImageTexture; // 通过 uniform 通道获取纹理信息。2D 纹理。
 
    void main()
    {
        gl_FragColor = texture2D(inputImageTexture, textureCoordinate); // texture2D 获取指定纹理在对应坐标位置的 rgba 颜色值，作为渲染管线最终要用的颜色信息。
    }
);
