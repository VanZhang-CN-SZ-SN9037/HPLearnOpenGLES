attribute vec4 v_position;
attribute vec4 v_color;

varying vec4 colorVarying;
void main(void) {
    colorVarying = v_color;
    gl_Position = v_position;
}
