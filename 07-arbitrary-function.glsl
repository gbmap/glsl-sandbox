
/* DOESNT WORK*/

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

#define N_STEPS 100

float sdf_scene(vec3 p)
{
    float x = p.x;
    float y = p.y;
    float z = abs(p.z);

    float fy = sin(p.x*PI);
    fy = p.x*p.x;

    float dx = x;
    float dz = (smoothstep(-0.1, 0., z-1.) - smoothstep(0.1, 0.0, z-1.))*z;
    // float dy = max(y + fy, 0.);
    float dy = y-fy;
    dx = min(dy, dz);

    float dd = min(min(dy, dz), dx);
    return p.y + fy;
    return max(dy,dz);
    dd = 100.;
    

    return min(max(p.y+(fy),dz) ,dd);
    // return vec3(p.x, )

    // return min(plane, sphere);
}

vec3 normal(vec3 p)
{
    float s = sdf_scene(p);
    vec2 a = vec2(0.01, 0.);
    vec3 n = s - vec3(
        sdf_scene(p-a.xyy),
        sdf_scene(p-a.yxy),
        sdf_scene(p-a.yyx)
    );

    return normalize(n);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv.x *= u_resolution.x / u_resolution.y;
    uv -= vec2(0.5);
    uv *= 2.;

    vec3 cpos = vec3(0., 3., -10.00);

    float sdf = 100.;

    vec3 rpos = cpos + vec3(u_mouse.x*0.05, 0., 0.);
    vec3 rdir = normalize(vec3(uv, 1.0));
    for (int i = 0; i < N_STEPS; i++)
    {
        float a = sdf_scene(rpos);
        rpos += rdir * a;
        sdf = a;
        if (a <= 0.01 || a >= 100.) break;
    }

    vec3 n = normal(rpos);

    vec3 color = vec3(sdf/10.);
    color = mix(n, vec3(0.), clamp(sdf,0.,1.));
    gl_FragColor = vec4(color, 1.0);
}