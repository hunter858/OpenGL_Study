precision highp float;
uniform sampler2D Texture;
varying vec2 TextureCoordsVarying;

uniform float Time;

void main(){
    
    float duration = 0.7;
    float maxAlpha = 0.4;
    float maxScale = 1.8;
   
    //0 ~ 100% = 1
    float progress = mod(Time, duration) / duration;
    //[0.4, 0]
    float alpha = maxAlpha * (1.0 - progress);
    //[1.0, 1.8]
    float scale = 1.0 + (maxScale - 1.0) * progress;
    
    float weakX = 0.5 + (TextureCoordsVarying.x - 0.5) / scale;
    float weakY = 0.5 + (TextureCoordsVarying.y - 0.5) / scale;
    vec2 weakTextureCoords = vec2(weakX, weakY);
    
    vec4 weakMask = texture2D(Texture, weakTextureCoords);
       
    vec4 mask = texture2D(Texture, TextureCoordsVarying);
    
//    gl_FragColor = mask * (1.0 - alpha) + weakMask * alpha;
    gl_FragColor = mix(mask, weakMask, alpha);
}

