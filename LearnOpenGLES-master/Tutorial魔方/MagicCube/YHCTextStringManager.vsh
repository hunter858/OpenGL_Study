attribute vec4 vertex;
attribute vec4 texture_coord;

varying vec4 varTextureCoord;

void main()
{
    vec4 position = vertex;
    position.y = position.y - 0.1;
    gl_Position = position;
    
    varTextureCoord = texture_coord;
}