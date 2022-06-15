precision highp float;
uniform sampler2D Texture;
varying vec2 TextureCoordsVarying;

uniform float Time;

const float PI = 3.1415926;

void main(){
    
    float duration = 0.6;
    //0 ~ 0.6
    float time = mod(Time, duration);
    
    vec4 whiteMask = vec4(1.0, 1.0, 1.0, 1.0);
    // 0 ~ 1
//    float amplitude = abs(sin(time * (PI / duration)));
    float amplitude = sin(time * (PI / duration));
    
   
    vec4 mask = texture2D(Texture, TextureCoordsVarying);
    gl_FragColor = mix(mask, whiteMask, amplitude);
}
