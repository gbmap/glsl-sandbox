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


/*
Works by essentially zeroing a triangle signal
with a square pulse that spans the two closest
data points from t.
*/
#define N_LERP_N(N, T) \
    T nlerp(const T[N] P, float t) { \
    float n = float(N)-1.; \
    float tn = t * n; \
    float lb = floor(tn); \
    float ub = ceil(tn); \
    float a = fract(tn); \
    float b = step(lb/n, t) - step(ub/n, t); \
    float tf = a*b; \
    return mix(P[int(lb)], P[int(ub)], tf); } \

N_LERP_N(3, vec3)

float f(float x) {
    return sin(x*PI)*x*x;
}

void main() {
    vec2 uv =  (gl_FragCoord.xy / u_resolution.xy);
    uv = uv*2.-1.;
    float y = f(uv.x);
    float t = abs(uv.y - y)-0.1;
    t = fract(t);


    vec3 color = mix(vec3(0.7529, 0.2196, 0.2196), vec3(0.2118, 0.1451, 0.2863), floor(t*10.)/10.);

    // vec3 color = vec3(t, t, t);
    gl_FragColor = vec4(color, 1.0);
}