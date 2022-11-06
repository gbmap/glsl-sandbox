#version 300 es
precision mediump float;
// #ifdef GL_ES
// #endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

#define LPOS vec3(1.+cos(u_time)*2., 1., -1.+sin(u_time)*2.)
#define CLR_AMBIENT vec3(0.29, 0.2, 0.25)*.75

float sdf_box(vec3 p, vec3 s)
{
    vec3 q = abs(p)-s;
    return length(max(q, 0.))+min(max(q.x,max(q.y,q.z)),0.);
}

float sdf_scene(vec3 p)
{
    vec2 s = vec2(.275, .75);
    float sph = length(p)-0.5;
    sph = max(-sdf_box(p, s.xxy),max(-sdf_box(p, s.yxx), max(-sdf_box(p, s.xyx), sph)));
    float plane = p.y+0.5;
    float sdf = min(sph-0.01, plane);
    return sdf;
}

float march(vec3 p, vec3 d)
{
    float h = 0.;
    vec3 cp = p;
    for (int i = 0; i < 200; i++)
    {
        float cd = sdf_scene(cp);
        h += cd;
        cp += d*cd;
        if (cd < 0.001 || cd > 999.) break;
    }
    return h;
}

vec3 lookat(vec3 p, vec2 uv, vec3 lookat, float fov)
{
    vec3 fwd = normalize(lookat-p);
    vec3 right = normalize(cross(vec3(0.,1.,0.), fwd));
    vec3 up = normalize(cross(fwd, right));
    return normalize(
        fwd*fov + right*uv.x + up*uv.y
    );
}

vec3 normal (vec3 p)
{
    vec2 e = vec2(0.01,0.);
    float d = sdf_scene(p);
    return normalize(
        d - vec3(
            sdf_scene(p-e.xyy),
            sdf_scene(p-e.yxy),
            sdf_scene(p-e.yyx)
        )
    );
}

vec3 shading(vec3 p, vec3 n, float d, vec3 cpos, vec3 lpos)
{
    vec3 ldir = normalize(lpos-p);
    float lambert = max(0., dot(ldir, n));
    vec3 clr = mix(CLR_AMBIENT, vec3(1.),lambert);
    return clr;
}


float shadow(vec3 p, vec3 n, vec3 lpos, float k)
{
    vec3 tolight = lpos-p;
    vec3 ray = normalize(tolight);
    float range = length(tolight);

    float res = 1.;
    for (float t = 0.1; t < 999.;)
    {
        float h = sdf_scene(p+ray*t);
        if (h < 0.001)
            return 0.;
        res = min(res, k*h/t);
        t += h;
        if (t > range)
            break;
    }
    return res;
}

float shadow_improved(vec3 p, vec3 n, vec3 lpos, float k)
{
    vec3 tolight = normalize(lpos - p);

    float y = 1.;
    float r1 = 1e-3;
    for (float t = 0.1; t < 10.;)
    {
        float d = sdf_scene(p+n*0.01+tolight*t);
        if (d < .01) return 0.;

        float x = (d*d)/(2.*r1);
        float xx = sqrt(d*d-x*x);

        y = min(y, k*xx/max(0., t-x));
        r1 = d;
        t += d;
    }
    return y;
}

out vec4 fragColor;

void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution.xy;
    uv = uv*2.-1.;
    uv.x *= u_resolution.x/u_resolution.y;

    vec3 cpos = vec3(0.75, 1., -3.);
    vec3 cdir = lookat(cpos, uv, vec3(0.), 1.);

    float t = march(cpos, cdir);
    vec3 p = cpos+cdir*t;
    vec3 color = vec3(0.);
    if (sdf_scene(cpos+cdir*t) <= 0.001)
    {
        color = normal(p);
    }
    vec3 n = normal(p);
    color = shading(p, n, t, cpos, LPOS);

    float s = 1.;
    float k = 60.*2.;
    if (uv.x > 0.0)
        s = shadow_improved(p, n, LPOS, k);
    else
        s = shadow(p, n, LPOS, k);
    color = mix(color, CLR_AMBIENT, 1.-s);

    fragColor = vec4(color, 1.0);
    // fragColor = vec4(1.,1.,1.,1.);
}