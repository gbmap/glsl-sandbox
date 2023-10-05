#version 300 es

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
#define CLR_AMBIENT vec3(0.1843, 0.1608, 0.1765)
#define SUN_DIR vec3(0.0, -1.0, 0.5)

float hash2f(vec2 uv)
{
    return fract(sin(dot(uv, vec2(12.35365, 4.423525)))*93423582.12123);
}

float smooth_min(float a, float b, float k)
{
    float h = clamp(0.5+0.5*(b-a)/k, 0., 1.);
    return mix(b,a,h)-k*h*(1.0-h);
}

// https://iquilezles.org/articles/distfunctions/
float sdCone( in vec3 p, in vec2 c, float h )
{
  // c is the sin/cos of the angle, h is height
  // Alternatively pass q instead of (c,h),
  // which is the point at the base in 2D
  vec2 q = h*vec2(c.x/c.y,-1.0);
    
  vec2 w = vec2( length(p.xz), p.y );
  vec2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
  vec2 b = w - q*vec2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
  float k = sign( q.y );
  float d = min(dot( a, a ),dot(b, b));
  float s = max( k*(w.x*q.y-w.y*q.x),k*(w.y-q.y)  );
  return sqrt(d)*sign(s);
}

vec4 scene(vec3 p)
{
    vec4 res = vec4(0.0);
    float plane = p.y + 1.; 
    // float total = min(plane, length(p)-.5);
    float total = 999.;
    vec3 r = vec3(.25, 1., .25);
    vec3 rp = mod(p+.5*r, r)-.5*r;
    rp.y = p.y;
    float cone = sdCone(rp, vec2(0.1, 0.5), 1.);
    if (cone < total)
        res.y = 1.;
    // total = min(cone, total);

    if (plane < total)
        res.y = 1.;
    total = min(total, plane);

    float s1 = length(p)- 2.;
    if (s1 < total)
        res.y = 2.;
    total = min(total, s1);
    total = min(total, length(p-vec3(1., 0., 10.))- 1.);


    res.x = total;
    return res;
}

float march(vec3 p, vec3 r)
{
    float s = 0.;
    for (int i = 0; i < 100; i++)
    {
        float d = scene(p).x;
        s += d;
        p += r * d;
        if (d <= 0.001 || s >= 100.) break;
    }

    return s;
}

vec3 normal(vec3 p)
{
    vec2 e = vec2(0.01, 0.);
    float d = scene(p).x;
    return normalize(d - vec3(
        scene(p-e.xyy).x,
        scene(p-e.yxy).x,
        scene(p-e.yyx).x
    ));
}

vec3 look(vec3 cp, vec3 look, vec2 uv, float fov)
{
    vec3 fwd = normalize(look - cp);
    vec3 right = cross(vec3(0., 1., 0.), fwd);
    vec3 up = cross(fwd, right);
    return normalize(right*uv.x+up*uv.y+fwd*radians(fov));
}

vec3 sky(vec3 p)
{
    return mix(
        vec3(0.2, 0.3, 0.4),
        vec3(0.8, 0.9, 1.),
        (dot(normalize(p), vec3(0.,1.,0.))+1.)*.5
    );
}


vec3 draw(vec3 cpos, vec3 cdir)
{
    float t = march(cpos, cdir);
    vec3 p = cpos+cdir*t;
    vec3 n = normal(p);

    vec3 lp = vec3(0.5, 3., 0.);

    vec3 color = sky(p);
    vec4 s = scene(p);
    if (t < 100.0)
    {
        if (s.y == 1.)
        {
            float a = max(0., dot(normalize(-SUN_DIR), n));
            color = mix(vec3(0.1725, 0.4471, 0.298), CLR_AMBIENT ,1.-a);
        }
        else
        {
            float a = max(0., dot(normalize(-SUN_DIR), n));
            color = CLR_AMBIENT*a;
        }
    }
    return color;
}

#define N_RAY_SAMPLES 8 

vec3 render(vec2 uv)
{
    vec2 m = ((u_mouse/u_resolution)*PI);
    float ds = 5.+m.y;
    vec3 cpos = vec3(-cos(m.x)*ds, 2.0, -sin(m.x)*ds);
    vec3 cdir = look(cpos, vec3(0.), uv, 60.);

    // depth pass 
    float t = march(cpos, cdir);
    vec3 color = vec3(0.);
    // color = draw(cpos,cdir);
    // return color;

    vec3 p1 = cross(cdir, vec3(0., 1., 0.));
    vec3 p2 = cross(cdir, p1);
    float dx = dFdx(uv.x);
    float dy = dFdy(uv.y);
    float amount = 20.;
    float spread = smoothstep(3., 10., pow(t,.5));

    for (int i = 0; i < N_RAY_SAMPLES; i++)
    {
        vec2 o = vec2(
            cos(float(i)/float(N_RAY_SAMPLES)*TWO_PI)*dx,
            sin(float(i)/float(N_RAY_SAMPLES)*TWO_PI)*dy
        )*spread*amount*(hash2f(vec2(float(i)))*2.-.5);

        vec3 offset = p1*o.x+p2*o.y;
        color += draw(cpos,cdir+offset)*(1./float(N_RAY_SAMPLES));
    }
    // return vec3(1.)*t/10.;
    return color;

    return color;
}

out vec4 fragColor;

void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution.xy;
    uv = uv * 2. - 1.;
    uv.x *= u_resolution.x/u_resolution.y;

    vec3 color = render(uv);
    fragColor = vec4(color, 1.0);
}