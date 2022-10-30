// #version 300 es
#extension GL_OES_standard_derivatives : enable

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

/*
https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
*/
float rand(float n){return fract(sin(n) * 43758.5453123);}

float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p){
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u*u*(3.0-2.0*u);
	
	float res = mix(
		mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
		mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
	return res*res;
}

float sdf_cube(vec3 p, vec3 sz)
{
    vec3 d = abs(p) - sz;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

vec4 sdf_scene(vec3 p)
{
    float m = 0.;
    float plane = sdf_cube(p-vec3(0.0, -4.0,0.0), vec3(5.0, 1.0, 5.0));
    m = step(plane, 100.);

    float sphere = length(p) - 3.00; 
    m = mix(m, 2., step(sphere,plane));

    float sdf = min(plane, sphere);
    m = mix(m, 0., step(length(p), sdf));
    return vec4(sdf, m, 0., 0.);
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

vec3 checker_board(vec2 uv)
{
    float t = sin(uv.x*10.0)*sin(uv.y*10.0);
    return mix(
        vec3(0.2627, 0.2275, 0.2745), 
        vec3(0.3627, 0.3275, 0.2745), 
        t
    );
}

vec3 m_color(float t, vec3 p)
{
    vec3 clr = vec3(0.);
    clr = mix(clr, checker_board(p.xz), step(0.5, t));
    clr = mix(clr, vec3(0.7137, 0.2039, 0.2039), step(1.5, t));
    // clr = mix(clr, vec3(0.), step(2.5, t));
    return clr;
}

float albedo(vec3 p, vec3 n, vec3 lpos)
{
    vec3 ldir = normalize(lpos - p);
    float ndotl = max(0., dot(ldir, n));
    return ndotl;
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
        if (a <= 0.01 || a >= 500.) break;
    }
    return sdf;
}

float shadow(vec3 p, vec3 n, vec3 lpos)
{
    vec3 dir = normalize(lpos-p);
    vec3 t1 = normalize(cross(n, n+vec3(0.1, 0.2, 0.3)));
    vec3 t2 = normalize(cross(t1, n));


    vec3 light_plane_tangent1 = cross(-dir, vec3(0.,1.,0.));
    vec3 light_plane_tangent2 = cross(-dir, light_plane_tangent1);

    // vec3 
    // vec3 light_plane_normal = ...;

    // noise sampling at light plane
    {
        float s = 0.;
        const int steps = 5;
        for (int i = 0; i < steps; i++)
        {
            float sampling_noise_x = rand(p.x);
            float sampling_noise_y = rand(p.y);
            vec2 circle = vec2(
                cos(sampling_noise_x*PI_TWO/4.0),
                sin(sampling_noise_y*PI_TWO/4.0)
            );

            vec3 plane_sampling_pos = (
                light_plane_tangent1*circle.x + light_plane_tangent2*circle.y
            )*5.0;
            // plane_sampling_pos *= noise(circle)*2.;


            vec3 light_pos = lpos+plane_sampling_pos;
            vec3 plane_lightdir = normalize(light_pos - p);
            float a = march(p+n*0.05, normalize(plane_lightdir));
            s += a;
        }
        s /= (float(steps));
        return 1./s;
    }
}

vec3 shading(vec4 scene, vec3 p, vec3 n, vec3 lpos, vec3 rdir, out float shad)
{
    if (scene.x >= 100.0)
    {
        vec3 p = normalize(p);

        float u = atan(p.z, p.x) / PI_TWO + 0.5; 
        float v = p.y * 0.5 + 0.5; 

        return texture2D(u_buffer0, vec2(u, v)).xyz;
    }

    vec3 clr = m_color(scene.y, p);
    float spec = specular(p, rdir, n, lpos, 50.);

    float a = albedo(p, n, lpos);
    clr *= max(0.25, a);
    clr += spec * vec3(1.0, 1.0, 1.0);

    float sh = max(0.5, min(1., 1.-shadow(p, n, lpos)));
    clr *= sh;
    shad = sh;
    return clr;
}

vec3 render(vec2 uv)
{
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

    vec3 lpos = vec3(5.*cos(u_time), 4., -5.5 * sin(u_time))*20.0;

    // shading
    float sh = 0.;
    vec3 color = shading(scene, rpos, n, lpos, rdir, sh);
    float spec = specular(rpos, rdir, n, lpos, 30.0);

    if (scene.y == 2.0) 
    {
        float reflectivity = 0.2*sh;
        vec3 reflected_dir = reflect(rdir, n);
        float reflected_d = march(rpos+n*0.02, reflected_dir);
        vec3 reflected_pos = rpos + n*reflected_d;

        vec4 scene = sdf_scene(reflected_pos);

        vec3 reflected_color = m_color(scene.y, reflected_pos);
        float ssh = 0.;
        reflected_color = shading(scene, reflected_pos, normal(reflected_pos), lpos, reflected_dir, ssh);
        float reflection = reflectivity/reflected_d;
        reflection = min(1., max(0., reflection));

        color = mix(color, reflected_color, reflectivity);
    }

    return color;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    // MSAA
    float dx = dFdx(uv.x);
    float dy = dFdy(uv.y);

    const int samples_count = 4;
    vec2 samples[4];
    samples[0] = vec2(0., 0.);
    samples[1] = vec2(dx, 0.0);
    samples[2] = vec2(0.0, dy);
    samples[3] = vec2(dx, dy);

    vec3 color = vec3(0.0);
    for (int i = 0; i < samples_count; i++)
        color += render(uv + samples[i]);
    color /= float(samples_count);
    
    gl_FragColor = vec4(color, 1.0);
}