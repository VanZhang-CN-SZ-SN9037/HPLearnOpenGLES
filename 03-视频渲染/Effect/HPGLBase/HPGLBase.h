//
//  HPGLBase.h
//  03-视频渲染
//
//  Created by Van Zhang on 2024/3/21.
//

#import <Foundation/Foundation.h>
// 定义了默认的 VertexShader 和 FragmentShader
#ifndef HPGLBase_h
#define HPGLBase_h

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

extern NSString *const HPDefaultVertexShader;
extern NSString *const HPDefaultFragmentShader;


#endif /* Header_h */
