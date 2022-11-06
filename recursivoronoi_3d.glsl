#extension GL_OES_standard_derivatives : enable
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
#define MAX_STEPS 100

#define SPHERE_SIZE 23.
#define iTime u_time

#define CLR_DARK vec3(0.233, 0.26, 0.228)*0.2

vec3 domain_repeat(vec3 p, vec3 c)
{
    vec3 q = mod(p+.5*c,c)-.5*c;
    return q;
}

float hash(float n)
{
    return fract(sin(n)*99999.5);
}

float hash2f(vec2 n)
{
    return fract(sin(dot(n, vec2(12.5,4.5)))*99999.9);
}

float noise(float x)
{
    float id = floor(x);
    float f = fract(x);

    float r = hash(id);
    float r2 = hash(id+1.);
    return mix(r, r2, smoothstep(0., 1., f));
}

float noise(vec2 x)
{
    vec2 id = floor(x);
    vec2 f = fract(x);

    float a = hash2f(id+vec2(0.,1.));
    float b = hash2f(id+vec2(1.,1.));
    float c = hash2f(id+vec2(1.,0.));
    float d = hash2f(id+vec2(0.,0.));

    return mix(
        mix(d, c, smoothstep(0., 1., f.x)),
        mix(a, b, smoothstep(0., 1., f.x)),
        smoothstep(0., 1., f.y)
    );
}

float voronoi(vec2 x, float t, float as)
{
    vec2 id = floor(x);
    vec2 f = fract(x);

    float y = 1.;
    for (int i = -1; i <= 1; i++)
    for (int j = -1; j <= 1; j++)
    {
        vec2 n = id+vec2(i,j);
        vec2 d = n-x+hash2f(n)+noise(vec2(cos(t), sin(t*.5))*as);
        y = min(y, dot(d,d));
    }
    return sqrt(y);
}


float pattern(vec2 uv)
{
    // return 0.;
    float uvz = 10.0;
    float t = voronoi(uv*uvz, iTime, .2);
    mat2 m = mat2(cos(t), -sin(t), sin(t), cos(t));
    uv = m*uv;
    return voronoi(uv*uvz, iTime*0.25, 0.5);
}

vec2 uv_sphere(vec3 p)
{
    vec2 uv;
    uv.x = atan(p.z, p.x) / TWO_PI + 0.5;
    uv.y = asin(p.y) / PI + 0.5;
    return uv;
}

float remap(float t, float minx, float maxx, float miny, float maxy)
{
    t = (t-minx)/(maxx-minx);
    return miny + t*(maxy-miny);
}

vec3 transform(vec3 p)
{
    p = domain_repeat(p, vec3(30.));
    p.y*=1./2.;

    float t = u_time*0.25;
    float ty = p.y * .15;
    t += sin(ty*2.)*.25;
    mat3 m = mat3(
        -sin(t), 0, cos(t), 
        0, 1, 0, 
        -cos(t), 0, -sin(t)
    );
    // p = m*p;
    float xzd = (cos(TWO_PI*p.y/SPHERE_SIZE)*.5+1.)*8.5;
    p.x += xzd*sign(p.x);
    p.z += xzd*sign(p.z);
    return p;
}

float get_pattern_height(vec2 uv, vec3 p)
{
    float t = pattern(uv);
    return t;


    float pattern_height = smoothstep(0.0, SPHERE_SIZE*1.5, length(p));
    // pattern_height = clamp(pattern_height, 0.,1.);
    // pattern_height = remap(pattern_height, 0., 0.6, 0., 1.);
    return pattern_height;
    // pattern_height = pow(pattern_height, 3.);
}


float sdf_scene(vec3 p)
{
    p = transform(p);
    vec2 uv = uv_sphere(p/SPHERE_SIZE);
    float height = (pattern(uv)-.5)*2.;
    return length(p) - SPHERE_SIZE - height;
}

vec3 normal(vec3 p)
{
    float d = sdf_scene(p);
    float epsilon = 0.01;
    vec2 e = vec2(epsilon, 0.);
    return normalize(
        vec3(
            sdf_scene(p-e.xyy)-d,
            sdf_scene(p-e.yxy)-d,
            sdf_scene(p-e.yyx)-d
        )
    );
}

float march(vec3 p, vec3 dir)
{
    float d = 0.;
    for (int i = 0; i < MAX_STEPS; i++)
    {
        float sdf = sdf_scene(p);
        p += dir*sdf;
        d += sdf;
        if (sdf <= 0.0001 || sdf >= 999.) break;
    }
    return d;
}

vec3 lookat(vec3 camp, vec3 look_at, vec2 uv, float fov)
{
    vec3 fwd = normalize(look_at - camp);
    vec3 right = normalize(cross(fwd, vec3(0., 1., 0.)));
    vec3 up = normalize(cross(right, fwd));
    return normalize(right*uv.x+up*uv.y+fwd*fov);
}


vec3 orbcolor(float t)
{
    vec3 color  =mix(
        vec3(0.2356, 0.1567, 0.01225),
        vec3(0.6356, 0.1567, 0.09225)*1.,
        1.-t
    );
    // color = vec3(t, sin(t*2.+t)*.5+.5, cos(t*2.)*.5+.5)*t;
    // color.g = voronoi(vec2(t,t), 0., 0.);
    return color;
}

vec3 shading(vec3 p, vec3 n, float d)
{
    vec3 color = vec3(0.);
    if (d >= 999.) return color;

    // vec3 lpos = vec3(SPHERE_SIZE*1.2, 0., SPHERE_SIZE*1.2);
    // vec3 sun_dir = normalize(lpos - p);

    vec3 sun_dir = vec3(0., -1., -.2);
    float albedo = max(0., dot(n, sun_dir));

    vec3 refl = reflect(-sun_dir, n);
    float spec = max(0., dot(n, refl));

    vec2 uv = uv_sphere(transform(p)/SPHERE_SIZE);
    float pattern_height = get_pattern_height(uv, p);

    color = mix(CLR_DARK, orbcolor(pattern_height), albedo)
            // + vec3(0.733, 0.527, 0.824)*pow(spec, 20.);
    ;
    // color = vec3(pattern_height)*albedo;
    return color;
}

vec3 render(vec2 uv)
{
    vec3 cpos = vec3(16.0,5.,20.);
    vec3 cdir = lookat(cpos, vec3(10., -2., 0.), uv, 1.);

    float t = march(cpos, cdir);

    vec3 color = vec3(0.);
    if (t < 999. && t >= 0.)
    {
        vec3 p = cpos+cdir*t;
        vec3 n = normal(p);
        color = shading(p,n,t);

        float d = clamp((t/200.), 0., 1.);
        d = clamp(log(0.9*d) + 1., 0., 1.);
        color = mix(color, CLR_DARK, d);
    }
    return color;
}

void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution.xy;
    uv.x*=u_resolution.x/u_resolution.y;
    uv = uv*2.-1.;

    vec3 color = render(uv);
    gl_FragColor = vec4(color, 1.0);
}