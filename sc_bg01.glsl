
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
#define E               2.7182818284

vec2 complex_exp(vec2 z)
{
    // e^x * cos(y) + i*e^x*sin(y)
    float ex = pow(E, z.x);
    return vec2(
        ex * cos(z.y),
        ex * sin(z.y)
    );
}

vec2 tile(vec2 uv, float t) {
    return fract(uv * t);
}

vec2 remap_to0(vec2 uv) {
    return uv*2.-1.;
}

vec2 complex_map(vec2 uv, float factor, vec2 c)
{
    return complex_exp(remap_to0(uv)*factor) + complex_exp(c);
}

vec2 to_polar(vec2 uv) {
    return vec2(
        length(uv),
        atan(uv.y, uv.x)
    );
}

float grid(vec2 uv, float t) {
    vec2 ss = step(0.05, fract(uv*t));
    return 1.-(ss.x*ss.y);
}

vec3 pattern_knots(vec2 uv, vec2 c, float f) {
    vec2 p = complex_map(uv, f, c);
    float t = pow(abs(p.x), abs(p.y));

    float gridt = grid(p, f);
    vec3 gridc = vec3(gridt);
    return vec3(p, t);
}

vec3 pattern_lights(vec2 uv, vec2 c, float zoom) {
    vec2 p = tile(uv, zoom);
    p = abs(remap_to0(p));
    p = complex_exp(p) + complex_exp(c);

    float gridt = grid(p, zoom);
    return vec3(p, pow(abs(p.x), abs(p.y)));
}


void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    // float t = mod(u_time,10.0);
    float t = u_time;
    uv.y += t*.15;
    uv.y = fract(uv.y);
    uv.x *= max(u_resolution.x, u_resolution.y) / u_resolution.y;

    // uv = to_polar(to_polar(to_polar(uv)));

    float f = 3.0;
    vec3 c = pattern_lights(uv, vec2(cos(t), sin(t)), f);

    vec3 clr = mix(
        vec3(sin(u_time*c.z), 0.6667, 0.302),
        vec3(0.6078, cos(u_time*c.y), 0.3333),
        c.x*c.y
    );

    vec3 cr = clr;
    gl_FragColor = vec4(cr, 1.0);
}
