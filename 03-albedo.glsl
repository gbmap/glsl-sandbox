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

vec4 sdf_scene(vec3 p)
{
    float m = 0.;
    float plane = p.y+3.0;
    m = step(plane, 100.)*1.;

    float sphere = length(p-vec3(0.)) - 3.00; 
    m = mix(m, 2., step(sphere,plane));
    return vec4(min(plane, sphere), m, 0., 0.);
}

vec3 normal(vec3 p)
{
    float s = sdf_scene(p).x;
    vec2 a = vec2(0.01, 0.);
    vec3 n = vec3(
        s - sdf_scene(p-a.xyy).x,
        s - sdf_scene(p-a.yxy).x,
        s - sdf_scene(p-a.yyx).x
    );

    return normalize(n);
}

vec3 m_color(float t)
{
    vec3 clr = vec3(0.);
    clr = mix(clr, vec3(0.2627, 0.2275, 0.2745), step(0.5, t));
    clr = mix(clr, vec3(0.7137, 0.2039, 0.2039), step(1.5, t));
    return clr;
}

vec3 albedo(vec3 clr, vec3 p, vec3 n, vec3 lpos)
{
    vec3 ldir = normalize(lpos - p);
    float ndotl = max(0., dot(ldir, n));
    return clr * ndotl;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv.x *= u_resolution.x / u_resolution.y;
    uv -= vec2(0.5);
    uv *= 2.;

    vec3 cpos = vec3(0., 1., -10.00);

    float sdf = 100.;

    vec3 rpos = cpos;
    vec3 rdir = normalize(vec3(uv, 1.0));
    for (int i = 0; i < N_STEPS; i++)
    {
        float a = sdf_scene(rpos).x;
        rpos += rdir * a;
        sdf = a;
        if (a <= 0.01 || a >= 100.) break;
    }

    vec3 n = normal(rpos);
    vec4 scene = sdf_scene(rpos);

    vec3 color = m_color(scene.y);
    color = albedo(color, rpos, n, vec3(3., 3., -3.5));
    
    //color = mix(n, vec3(0.), clamp(scene.x,0.,1.));
    gl_FragColor = vec4(color, 1.0);
}