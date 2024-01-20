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

#define MAX_STEPS 256

float sdf_scene(vec3 p) {

    // p = fract(p/100.)-0.5;


    float xz = sin(u_time+p.y*PI*3.)*0.1
        *(1.0/length(p-vec3(0.,0.,2.)));
    vec3 offset = vec3(xz, sin(u_time+p.x*PI*3.)*0.1, xz);

    float sphere = length(p - vec3(0., 0., 2.) - offset) - 1.;
    // p.xz -= xz;
    // p.y -= 

    float cube = length(
        max(vec3(0., 0., 0.), 
        abs(p-offset-vec3(2.0, 0., 2.))-vec3(0.5, 0.5, 0.5)
        )
    );
    return min(sphere, cube);
}

vec3 cam_dir(vec3 cpos, vec2 uv, vec3 look_at) {
    float fov = radians(60.);

    vec3 z = normalize(look_at - cpos);
    vec3 x = cross(vec3(0., 1., 0.), z);
    vec3 y = cross(z, x);

    return normalize(x * uv.x + y * uv.y + z*fov);
}

vec3 normal(vec3 p) {
    float d = sdf_scene(p);
    float du = 0.005;

    float x = d - sdf_scene(p - vec3(du, 0., 0.));
    float y = d - sdf_scene(p - vec3(0., du, 0.));
    float z = d - sdf_scene(p - vec3(0., 0., du));
    return normalize(vec3(x, y, z))*.5+.5;
}


void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution.xy;
    uv = uv*2.-1.;


    vec3 p_cam = vec3(5., 3., -0.5);
    vec3 p_dir = cam_dir(p_cam, uv, vec3(2., 0., 2.));
    vec3 p = p_cam;
    float d = 0.;

    for (int i = 0; i < MAX_STEPS; i++) {
        float _d = sdf_scene(p); 
        d += _d;
        p += p_dir * _d;

        if (d <= 0.001 || d>= 1000.) break;
    }

    // t = step(length(uv), 0.5);
    float t = 0.0;
    t = d/5.;

    vec3 n = normal(p);

    vec3 clr = vec3(t, t, t);
    clr = n;
    gl_FragColor = vec4(clr, 1.0);
}