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


uniform vec3 colors[10] = vec3[10] (
        vec3(1.0, 0.0, 0.0),
        vec3(0.0, 1.0, 0.0),
        vec3(0.0275, 0.0275, 0.0549),
        vec3(0., 0., 0.),
        vec3(0., 0., 0.),
        vec3(0., 0., 0.),
        vec3(0., 0., 0.),
        vec3(0., 0., 0.),
        vec3(0., 0., 0.),
        vec3(0., 0., 0.),
        vec3(0., 0., 0.)
);

// 10 = arbitrary value so it compiles
vec3 nlerp_v3(vec3[10] P, float t, int n) {
    float tn = t * float(n);
    float lb = floor(tn);
    float ub = ceil(tn);
    float tf = fract(tn) * (step(lb/float(n), t)-step(ub/float(n), t));

    vec3 f = vec3(0.);

    for (int i = 0; i < 10-1; i++) {
        f += mix(P[i], P[i+1], tf)*tf;
    }

    return f;

    // this would be ideal.
    // return mix(P[int(lb)], P[int(ub)], tf);
}

void main() {
    vec3 color = vec3(0., 0., 0.);

    gl_FragColor = vec4(color, 1.0);
}
