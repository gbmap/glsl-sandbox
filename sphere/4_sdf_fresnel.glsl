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

/*
n1 = index of refraction of the first medium
n2 = index of refraction of the second medium
n = normal
inc = incident ray
f0 = minimum reflectance
f90 = maximum reflectance
https://blog.demofox.org/2020/06/14/casual-shadertoy-path-tracing-3-fresnel-rough-refraction-absorption-orbit-camera/
*/
float fresnel(float n1, float n2, vec3 n, vec3 inc, float f0, float f90)
{
    float r0 = (n1-n2)/(n1+n2);
    r0 *= r0;
    float cosX = -dot(n, inc);
    float x = 1.0 - cosX;
    float ret = r0+(1.0-r0)*x*x*x*x*x;
    return mix(f0, f90, ret);
}

vec3 albedo(vec3 clr, vec3 p, vec3 n, vec3 lpos)
{
    vec3 ldir = normalize(lpos - p);
    float ndotl = max(0., dot(ldir, n));
    return clr * ndotl;
}

float march(vec3 rpos, vec3 rdir)
{
    float sdf = 0.;
    for (int i = 0; i < N_STEPS; i++)
    {
        float a = sdf_scene(rpos).x;
        rpos += rdir * a;
        sdf += a;
        if (a <= 0.01 || a >= 100.) break;
    }
    return sdf;
}

float shadow(vec3 p, vec3 n, vec3 lpos)
{
    vec3 dir = normalize(lpos-p);
    float d = march(p+n*0.2, dir);
    return clamp(d/length(lpos-p), 0., 1.);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv.x *= u_resolution.x / u_resolution.y;
    uv -= vec2(0.5);
    uv *= 2.;

    vec3 cpos = vec3(0., 1., -10.00);
    vec3 rpos = cpos;
    vec3 rdir = normalize(vec3(uv, 1.0));
    float d = march(rpos, rdir);
    rpos += rdir*d;

    vec3 n = normal(rpos);
    vec4 scene = sdf_scene(rpos);

    vec3 lpos = vec3(3.*cos(u_time), 3., -3.5 * sin(u_time));

    float ss = shadow(rpos, n, lpos);

    vec3 color = m_color(scene.y);
    color = albedo(color, rpos, n, lpos);
    color *= ss;

    if (scene.y == 2.0)
    {
        float f = fresnel(0.5, 1.0, n, rdir, 0.0, 0.275);
        color = mix(color, vec3(1.00, 0.23, 0.15),f);
    }
    
    //color = mix(n, vec3(0.), clamp(scene.x,0.,1.));
    gl_FragColor = vec4(color, 1.0);
}