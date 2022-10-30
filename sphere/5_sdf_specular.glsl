/* Main function, uniforms & utils */
#ifdef GL_ES
    precision mediump float;
#endif

uniform sampler2D u_buffer0;

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

    float sphere = length(p) - 3.00; 
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

/*
blinn-phong
*/
float specular(vec3 p, vec3 rdir, vec3 n, vec3 lpos, float shininess)
{
    vec3 ldir = normalize(lpos - p);
    vec3 r = reflect(-ldir, n);
    float s = max(dot(r, -rdir), 0.);
    return pow(s, shininess/4.0);
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
    // gl_FragColor = texture2D(u_buffer0, uv);
    // return;
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

    vec3 lpos = vec3(5.*cos(u_time), 4., -5.5 * sin(u_time))*4.0;
    // lpos = vec3(2.0, 4.0, -15.0);

    vec3 color = m_color(scene.y);
    color = albedo(color, rpos, n, lpos);
    color *= shadow(rpos, n, lpos);

    float spec = specular(rpos, rdir, n, lpos, 25.);
    color += spec * vec3(1.0, 1.0, 1.0)*(10.0/length(lpos-rpos));

    gl_FragColor = vec4(color, 1.0);

    float uv_x = (dot(vec2(0.0,1.0), rdir.xz)+1.)*0.5;
    float uv_y = dot(vec2(1.0,0.0), rdir.yz);
    
}