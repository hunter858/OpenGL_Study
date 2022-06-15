
uniform mat4 uMVPMatrix;
attribute vec4 vPosition;
attribute vec4 myTexCoord;
varying vec4 VaryingTexCoord0;
void main()
{   
	VaryingTexCoord0 = myTexCoord;
	gl_Position = vPosition;
}