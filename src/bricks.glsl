
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


float pulse(vec2 p, float t, float w)
{
    return smoothstep(t, t+w*.5, p.x)*smoothstep(t+w, t+w*.5, p.x);
}

float bricks(vec2 p)
{
    p = fract(p*vec2(1.25,1.75)-vec2(0.1, 0.3));
    vec2 ss = max(smoothstep(0.9, 1., p), smoothstep(0.1, 0.0, p));
    return max(ss.x,ss.y);
    return pulse(p, 0.2, .06125);
}

void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution.xy;
    float t = bricks(uv);
    vec3 color = vec3(
        t,t,t
    );

    gl_FragColor = vec4(color, 1.0);
}