
varying lowp vec4 varyColor;
uniform lowp float saturation;
const mediump vec3 weighting = vec3(0.2125, 0.7154, 0.0721);

void main()
{
    lowp float weight = dot(varyColor.rgb, weighting);
    lowp vec3 grayColor = vec3(weight);
    
    gl_FragColor = vec4(mix(grayColor, varyColor.rgb, saturation), varyColor.w);
//    gl_FragColor = varyColor;
}
