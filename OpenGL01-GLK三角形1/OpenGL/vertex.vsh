attribute vec3 a_Position;
void main(void) {
    gl_Position = vec4(a_Position, 1.0);
}
