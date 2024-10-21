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
#define CLR_AMBIENT sky(p)*.5
#define SUN_POS vec3(-0.2, 0.25, .5)*100.
#define SUN_DIR normalize(-SUN_POS)
#define SKY_CLR_A vec3(0.5725, 0.349, 0.9922)
#define SKY_CLR_B vec3(0.0784, 0.5373, 0.9647)
#define SUN_CLR_A vec3(0.9922, 0.5294, 0.1294)
#define SUN_CLR_B vec3(0.9922, 0.8549, 0.1725)
#define SUN_CLR_C vec3(1.0, 1.0, 1.0)
#define GRASS_COLOR vec3(0.2784, 0.7647, 0.498)
#define CASTLE_COLOR vec3(0.3137, 0.3333, 0.4745)
#define FOG_AMOUNT 0.01
#define GRASS_REPEAT vec3(.25, 1., .25);
#define SHADOW_CLR vec3(0.198, 0.013, 0.167)

#define SHADOW_F 0.35

float hash(float x)
{
    return fract(sin(x)*43242.2352323);
}

float hash2f(vec2 p)
{
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(float x)
{
    float id = floor(x);
    float f = fract(x);
    return mix(hash(id), hash(id+1.), f);
}

float noise(vec2 p)
{
    vec2 id = floor(p);
    vec2 f = fract(p);

    vec2 o = vec2(1., 0.);
    float a = hash2f(id);
    float b = hash2f(id+o.xy);
    float c = hash2f(id+o.yx);
    float d=  hash2f(id+o.xx);

    return mix(
        mix(a,b,f.x),
        mix(c,d,f.x),
        f.y
    );
}

float height_map(vec2 st)
{
    vec2 x1 = vec2(0.);
    vec2 x2 = vec2(0.);
    float a = 1.25;
    st *= .25;
    for (int i = 0; i < 8; i++)
    {
        x1 += sin(st)*a;
        x2 += cos(st)*a;
        st *= .5;
        st += cos(st)*2.*float(i);
        a *= .5;
    }

    return dot(x1, x2);
}

float smooth_min(float a, float b, float k)
{
    float h = clamp(0.5+0.5*(b-a)/k, 0., 1.);
    return mix(b,a,h)-k*h*(1.0-h);
}

float box(vec3 p, vec3 s)
{
    vec3 q = abs(p) - s;
    return length(max(q, 0.))+min(max(q.x,max(q.y,q.z)),0.);
    return max(q.x, max(q.y, q.z));
}

float pulse(vec2 p, float t, float w)
{
    return smoothstep(t, t+w*.5, p.x)*smoothstep(t+w, t+w*.5, p.x);
}

float bricks(vec2 p)
{
    p = fract(p*vec2(1.25,1.75)-vec2(0.1, 0.3));
    vec2 ss = max(smoothstep(0.9, 1., p), smoothstep(0.1, 0.0, p));
    return max(ss.x,ss.y);
    return pulse(p, 0.2, .06125);
}

float castle(vec3 p)
{
    vec3 csz = vec3(1.25, 2.5, 1.25);
    float roundness = .05;

    // base shape
    float s = box(p-vec3(0., csz.y, 0.), csz); 

    float tes = .25; // tower extrusion size
    vec3 tp0 = vec3(abs(p.x), p.y-roundness*2., abs(p.z));
    vec3 tpo = vec3(0., csz.y*2.-tes, 2.*csz.z/5.);
    vec3 sz = vec3(csz.x*1.2, tes+roundness, csz.z/5.);
    float top_extract = min(box(tp0-tpo, sz), box(tp0-tpo.zyx, sz.zyx));
    s = max(-top_extract, s);

    vec3 bp = fract(p);
    // float br = bricks(bp.xy) + bricks(bp.yz);
    float br = noise(bp.xy) + bricks(bp.xz);
    s += br*.5*.1;

    float crown = box(p-vec3(0., csz.y*2.-4.*tes, 0.), vec3(csz.x+.15, tes, csz.z+.15));
    s = min(crown, s);

    return s-roundness;
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

float trees(vec3 p)
{
    vec3 r = vec3(1.75, 1., 1.75);
    vec3 rp = mod(p+.5*r, r)-.5*r;
    rp.y = p.y;

    vec3 frp = floor(.5+p/r);
    float frpn = noise(frp.xz);
    if (frpn < .5)
        return 999.;

    // if (noise(floor((r.xz+p.xz)/r.xz/2.)) < .5) return 999.;

    float t = 999.;
    float ch = hash2f(floor(.5+p/r).xz)*.025;
    ch = 0.1;
    float h = 1.+ch;
    vec2 csz = vec2(.15, .35);
    for (int i = 0; i < 3; i++)
    {
        vec3 to = vec3(0., 4.-h+float(i)*h*.5, 0.);
        t = min(t, sdCone(rp-to, csz, h)/2.);
    }
    return t;
}

vec4 scene(vec3 p)
{
    vec4 res = vec4(0.0);

    float plane_y_offset = height_map(p.xz);
    float plane_y = p.y - plane_y_offset;
    float plane = plane_y; 
    // float total = min(plane, length(p)-.5);
    float total = plane;
    res.y = 1.;
    vec3 r = GRASS_REPEAT;
    vec3 rp = mod(p+.5*r, r)-.5*r;
    // rp.y -= hash2f(floor(p.xz))*0.01;
    rp.y = p.y -plane_y_offset;
    float cone = sdCone(rp-vec3(0.,.25,0.), vec2(0.05, 0.25), 0.25)/2.;
    if (cone < total)
        res.y = 1.;
    total = min(cone, total);

    float c = castle(p-vec3(3., plane_y_offset, 2.5));
    // c= length(p-vec3(3., plane_y_offset+1., 2.5))-1.;
    if (c < total)
        res.y = 2.;
    total = min(c, total);

    float t = trees(p-vec3(0., plane_y_offset, 0.));
    total = min(t, total);

    res.x = total;
    return res;
}

float march(vec3 p, vec3 r)
{
    float s = 0.;
    for (int i = 0; i < 200; i++)
    {
        float d = scene(p).x;
        s += d;
        p += r * d;
        if (d <= 0.001 || s >= 200.) break;
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
    vec3 d = normalize(p);
    vec3 skyclr = mix(
        SKY_CLR_A,
        SKY_CLR_B,
        max(0., dot(d, vec3(0.,1.,0.)))
    );

    vec3 sun_pos = SUN_POS;

    float st = max(0., dot(d, normalize(sun_pos)));
    vec3 sun_clr = mix(SUN_CLR_A, SUN_CLR_B, st);
    sun_clr = mix(sun_clr, SUN_CLR_C, smoothstep(0.95, 1.0, st));

    skyclr = mix(skyclr, sun_clr, max(0.,st*st));

    return skyclr;
}

float shadow(vec3 p, vec3 lpos)
{
    vec3 tol = normalize(lpos-p);
    float t = march(p, tol);
    if (t < length(lpos-p))
        return 1.;
    return 0.;
}

// r = ray
// s = distance
// p = point
// b = amount
vec3 fog(vec3 p, vec3 r, float s, vec3 c)
{
    vec3 fogcolor = sky(p);
    float tt = max(0., dot(-SUN_DIR, r));
    float t = exp(-s*FOG_AMOUNT);
    return mix(fogcolor, c, clamp(t, 0., 1.));
}

vec3 mat(vec3 clr, vec3 p, vec3 n, vec3 r, float k_s)
{
    // vec3 nt1 = normalize(cross(n, vec3(0., 1., 0.)));
    // vec3 nt2 = normalize(cross(n, nt1));
    float nf = 400.;
    vec3 pn = p*nf;
    n = normalize(n + vec3(noise(pn.x), noise(pn.y), noise(pn.z)) * 0.04);

    float a = max(0., dot(normalize(-SUN_DIR), n));
    float s = pow(max(0., dot(reflect(r, n), -SUN_DIR)), k_s);
    clr = mix(clr, CLR_AMBIENT ,(1.-a)*.5);
    clr = clr+s*SUN_CLR_A*.5; 
    return clr;
}

vec3 render(vec2 uv)
{
    vec2 m = ((u_mouse/u_resolution)*PI);
    // float ds = 7.5+m.y;
    // vec3 cpos = vec3(-cos(m.x)*ds, 4.0, -sin(m.x)*ds);
    // vec3 cdir = look(cpos, vec3(0., 3., 0.), uv, 100.);
    float ds = 10.5+m.y;
    vec3 cpos = vec3(-cos(m.x)*ds, 10.0, -sin(m.x)*ds);
    vec3 cdir = look(cpos, vec3(0., 5., 0.), uv, 100.);

    float t = march(cpos, cdir);

    vec3 p = cpos+cdir*t;
    vec3 n = normal(p);

    vec3 lp = vec3(0.5, 3., 0.);

    vec3 color = sky(p);
    vec4 s = scene(p);
    if (t < 200.)
    {
        if (s.y == 1.)
        {
            color = mat(GRASS_COLOR, p, n, cdir, 20.);
        }
        else if (s.y == 2.)
        {
            color = mat(CASTLE_COLOR, p, n, cdir, 20.);
        }
        else
        {
            float a = max(0., dot(normalize(-SUN_DIR), n));
            color = CLR_AMBIENT*a;
        }

        float ao = smoothstep(0., 0.05, scene(p+n*0.025).x)*.5+.5;
        color = mix(CLR_AMBIENT, color, ao);

        float sh = shadow(p+n*0.01, SUN_POS)*SHADOW_F;
        color = mix(SHADOW_CLR, color, clamp(1.-sh,0.,1.));
        color = fog(p, cdir, t, color);
    }

    return color;
}

out vec4 fragColor;

void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution.xy;
    uv = uv * 2. - 1.;
    uv.x *= u_resolution.x/u_resolution.y;

    vec3 color = render(uv);

    // vec2 r = vec2(4.);
    // vec2 uv2 = uv*10.;
    // vec2 rp = mod(uv2-r*.5,r)-0.5*r;
    // vec2 aa = floor(.5+uv2/r/2.);
    // float ab = noise(aa);
    // color = vec3(aa, ab);
    // color = (
    //   render(uv)
    // + render(uv+vec2(dFdx(uv.x)*.5, 0.))
    // + render(uv-vec2(dFdx(uv.x)*.5, 0.))
    // + render(uv+vec2(0., dFdy(uv.y)*.5))
    // + render(uv+vec2(0., -dFdy(uv.y)*.5))
    // )/5.;
    // color = pow(color, vec3(2.5/2.2));
    fragColor = vec4(color, 1.0);
}