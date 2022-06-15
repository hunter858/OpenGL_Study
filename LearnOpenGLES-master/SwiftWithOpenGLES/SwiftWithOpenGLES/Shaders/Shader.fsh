//
//  Shader.fsh
//  SwiftWithOpenGLES
//
//  Created by 林伟池 on 16/4/12.
//  Copyright © 2016年 林伟池. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
