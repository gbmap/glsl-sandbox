
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
    return length(p-vec3(0.)) - 3.00;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv.x *= u_resolution.x / u_resolution.y;
    uv -= vec2(0.5);
    uv *= 2.;

    vec3 cpos = vec3(0., 0., -10.00);

    float sdf = 100.;

    vec3 rpos = cpos;
    vec3 rdir = normalize(vec3(uv, 1.0));
    for (int i = 0; i < N_STEPS; i++)
    {
        float a = sdf_scene(rpos);
        rpos += rdir * a;
        sdf = a;
        if (a <= 0.01 || a >= 100.) break;
    }

    //vec3 n = normal(rpos);
    vec3 color = vec3(sdf/10.);
    //color = mix(n, vec3(0.), sdf);
    gl_FragColor = vec4(color, 1.0);
}
