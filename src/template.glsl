/* Main function, uniforms & utils */
#ifdef GL_ES
    precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

#define PI_TWO			1.570796326794897
#define PI				3.141592653589793
#define TWO_PI			6.283185307179586

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    float t = dot(uv.xy-.5, vec2(-.5, .0));
    vec3 color = vec3(
        t,t,t
    );

    gl_FragColor = vec4(color, 1.0);
}