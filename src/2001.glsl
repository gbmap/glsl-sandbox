
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
#define CLR_AMBIENT vec3(0.7, 0.63, 0.66)


float scene(vec3 p)
{
    float plane = p.y +2.; // - sin(p.x/2.)*.6; //  + abs(p.z);// + p.x*p.z;
    return length(p) -1.;
    return min(plane, length(p) - 1.);
}

float march(vec3 p, vec3 r)
{
    float s = 0.;
    for (int i = 0; i < 100; i++)
    {
        float d = scene(p);
        s += d;
        p += r * d;
        if (d <= 0.001 || s >= 100.) break;
    }

    return s;
}

vec3 normal(vec3 p)
{
    vec2 e = vec2(0.01, 0.);
    float d = scene(p);
    return normalize(d - vec3(
        scene(p-e.xyy),
        scene(p-e.yxy),
        scene(p-e.yyx)
    ));
}

vec3 look(vec3 cp, vec3 look, vec2 uv, float fov)
{
    vec3 fwd = normalize(look - cp);
    vec3 right = cross(vec3(0., 1., 0.), fwd);
    vec3 up = cross(fwd, right);
    return normalize(right + uv.x + up * uv.y + fwd * radians(fov));
}

void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution.xy;
    uv = uv * 2. - 1.;
    uv.x *= u_resolution.x/u_resolution.y;

    vec3 cpos = vec3(0., 0., -2.);
    vec3 cdir = normalize(vec3(uv, 1.));
    // vec3 cdir = look(cpos, vec3(0.), uv, 60.);

    float t = march(cpos, cdir);
    vec3 p = cpos+cdir*t;
    vec3 n = normal(p);

    vec3 lp = vec3(0.5, 3., 0.);

    float a = max(0., dot(normalize(lp-p), n));
    vec3 color = CLR_AMBIENT*a;
    gl_FragColor = vec4(color, 1.0);
}