//
//  Shader.fsh
//  TestOpenGL
//
//  Created by apple on 12-5-31.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//


uniform sampler2D Ytex;
uniform sampler2D Utex;
uniform sampler2D Vtex;
precision mediump float;
varying vec4 VaryingTexCoord0;
vec4 color;

void main()
{
	float yuv0 = (texture2D(Ytex,VaryingTexCoord0.xy)).r;
	float yuv1 = (texture2D(Utex,VaryingTexCoord0.xy)).r;
	float yuv2 = (texture2D(Vtex,VaryingTexCoord0.xy)).r;
    
    //mediump vec3 yuv;
    //lowp vec3 rgb;
    
    //yuv.x = texture2D(Ytex, VaryingTexCoord0.xy).r;
    //yuv.y = texture2D(Utex, VaryingTexCoord0.xy).r - 0.5;
    //yuv.z = texture2D(Vtex, VaryingTexCoord0.xy).r - 0.5;

    //rgb = mat3( 1,       1,         1,
    //            0,       -0.39465,  2.03211,
     //           1.13983, -0.58060,  0) * yuv;
    
    //gl_FragColor = vec4(rgb, 1);
    
    
  
	
	color.r = yuv0 + 1.4022 * yuv2 - 0.7011;
	color.r = (color.r < 0.0) ? 0.0 : ((color.r > 1.0) ? 1.0 : color.r);
	color.g = yuv0 - 0.3456 * yuv1 - 0.7145 * yuv2 + 0.53005;
    color.g = (color.g < 0.0) ? 0.0 : ((color.g > 1.0) ? 1.0 : color.g);
	color.b = yuv0 + 1.771 * yuv1 - 0.8855;
	color.b = (color.b < 0.0) ? 0.0 : ((color.b > 1.0) ? 1.0 : color.b);
	gl_FragColor = color;
}