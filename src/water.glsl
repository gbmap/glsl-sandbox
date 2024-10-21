#version 300 es
#ifdef GL_ES
    precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

#define PI_TWO			1.570796326794897
#define PI				3.141592653589793
#define TWO_PI			6.283185307179586
#define BOAT_POS vec3(0.,0.565,0.)
#define LCOLOR vec3(0.932, 0.55, 0.4)
#define LPOS vec3(0.,0.5,-2.)
#define LDIR normalize(vec3(-1., -1., -1.))


float hash2f(vec2 x)
{
    return fract(sin(dot(x, vec2(12.98985, 78.233545))) * 43758.5453);
}

float noise(vec2 x)
{
    vec2 id = floor(x);
    vec2 f = fract(x);

    vec2 e = vec2(0., 1.);
    float a = hash2f(id);
    float b = hash2f(id+e.yx);
    float c = hash2f(id+e.xy);
    float d = hash2f(id+e.yy);

    return mix(
    mix(a,b, f.x),
    mix(c,d, f.x),
    f.y
    );
}

// https://iquilezles.org/articles/distfunctions/
float hexprism(vec3 p, vec2 h)
{
const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
  p = abs(p);
  p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
  vec2 d = vec2(
       length(p.xy-vec2(clamp(p.x,-k.z*h.x,k.z*h.x), h.x))*sign(p.y-h.x),
       p.z-h.y );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// Simplex 2D noise
//
// https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
vec3 permute(vec3 x) { return mod(((x*34.0)+1.0)*x, 289.0); }

float snoise(vec2 v){
  const vec4 C = vec4(0.211324865405187, 0.366025403784439,
           -0.577350269189626, 0.024390243902439);
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);
  vec2 i1;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;
  i = mod(i, 289.0);
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
  + i.x + vec3(0.0, i1.x, 1.0 ));
  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy),
    dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;
  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

float water_y(vec2 uv)
{
    return snoise(.5*uv+vec2(u_time*.25,0.))*1.3; // + snoise(u_time+uv*10.)*.01-.005;
}

mat3 rotate_boat(vec3 p)
{
    float e = 0.1;
    float w = water_y(vec2(0., 0.));
    float wx = water_y(vec2(e,0.0));
    float wy = water_y(vec2(0.0,e));

    float rf = 1.0;
    float tx = (wx-w)*rf;
    float ty = (wy-w)*rf;
    return mat3(
        1., 0., 0.,
        0., cos(tx), -sin(tx),
        0., sin(tx), cos(tx)
    )*mat3(
        cos(ty), -sin(ty), 0.,
        sin(ty), cos(ty), 0.,
        0., 0., 1.
    );
}

vec3 transform_boat(vec3 p)
{
    float y = water_y(vec2(0.0));
    p.y += y*.2;
    p = rotate_boat(p)*p;

    p = p.xzy;
    p.z*=1.7;
    p.x*=.5;
    p.z -= 1.35*p.x*p.x;
    p.xy -= p.z*sign(p.xy)*0.1;
    return p;
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float sqr(vec2 uv, vec2 sz)
{
    vec2 q = abs(uv)-sz;
    return max(q.x, q.y);
}

vec3 flag_texture(vec2 uv)
{
    uv *=2.;
    uv *= .75;

    vec2 skull_uv = uv;
    skull_uv.y *= clamp(0., 2., uv.y*5.);
    float skull = length(skull_uv)-.25;
    float jaw = sqr(uv-vec2(0., -0.175), vec2(0.15, 0.125)); 

    vec2 teeth_uv = uv-vec2(0.0125,0.);
    teeth_uv *= 20.;
    teeth_uv.x = fract(teeth_uv.x);
    teeth_uv -= vec2(0., -6.);
    float teeth = sqr(teeth_uv-vec2(.1,0.2), vec2(0.25, 0.5)); 
    
    float t = opSmoothUnion(skull, jaw, 0.05);
    t = max(-teeth, jaw);
    t = opSmoothUnion(t, skull, 0.05);

    float rt = radians(-45.);
    mat2 r = mat2(cos(rt), -sin(rt), sin(rt), cos(rt));

    vec2 eyes_uv = uv;
    eyes_uv.x = abs(eyes_uv.x);
    eyes_uv= r*eyes_uv;
    eyes_uv.x*=1.5;
    float eyes = length(eyes_uv-vec2(0.2,0.)) - 0.1;

    vec2 nose_uv = uv-vec2(0., -0.16);
    nose_uv.x = abs(nose_uv.x);
    nose_uv = r*nose_uv;
    nose_uv.x *= 1.2;
    float nose = length(nose_uv - vec2(0.03, 0.))-0.01;
    eyes = min(nose, eyes);
    t = max(-eyes, t);

    vec2 bone_end_uv = uv;
    bone_end_uv = r*bone_end_uv;
    bone_end_uv = abs(bone_end_uv);
    bone_end_uv = abs(bone_end_uv-vec2(0.085, 0.45));
    bone_end_uv = pow(bone_end_uv,vec2(1.275));

    float b1 = length(bone_end_uv);
    bone_end_uv = r*r*bone_end_uv;
    float b2 = length(bone_end_uv);
    float bone_end = min(b1,b2)-0.05;

    vec2 bone_uv = uv;
    float bone = sqr(r*bone_uv, vec2(0.1, 0.4));

    t = 1.-step(0., t);
    return vec3(1.)*t;
}

float boat_flag(vec3 p, out vec2 flag_uv)
{
    if (length(p)>1.2)
        return 999.;

    p.x += -.05;
    flag_uv = p.zy;
    float fa = ((p.x+.2)/0.5);
    vec3 d = vec3(.2, .15, 0.005)*1.5;
    float s = abs(sin(u_time*.4+snoise(vec2(u_time))*.4));
    p.x += s*.05+.4+(2.*-p.y)*(2.*p.y)*(.65+s*.25);
    vec3 q = (abs(p)-d.zyx);
    return max(q.x, max(q.y,q.z))/5.;
}

float boat_mast(vec3 p, out float mat, out vec2 flag_uv)
{
    float y = 0.;
    p.y += water_y(vec2(0.0))*.2;
    p.y += 0.1;
    p = rotate_boat(p)*p;

    float hm = 100.;
    for (int i = 1; i <= 2; i++)
    {
        vec3 hp = p-vec3(0.045, float(i)*((0.77-float(2-i)*.1)*.5),-.75*.5);
        hp.z -= clamp(hp.z, 0., .75);
        hm = min(hm, length(hp)-0.0175);
    }

    p.x = -p.x;
    float f = boat_flag(p-vec3(0.175, 0.55,0.), flag_uv);

    p.y -= clamp(p.y, 0.0, 1.); 
    float m = length(p)-0.025;

    m = min(hm, m);

    if (f < m)
        mat = 2.;
    else
        mat = 1.;
    
    return min(f, m);
}

float boat(vec3 p, bool hollow, out float m, out vec2 flag_uv)
{
    vec3 bp = transform_boat(p);
    vec2 h = vec2(0.25, 0.25);
    
    float b = hexprism(bp, h);
    if (hollow)
        b = max(-hexprism(bp-vec3(0.,0.,0.1), vec2(0.2, h)), b);

    float bm = boat_mast(p,m, flag_uv);
    float bb = b/2.;
    if (bb < bm)
        m = 1.;

    return min(b/2., bm);
}

float voronoi(vec2 uv) {
    vec2 p = floor(uv);
    vec2 f = fract(uv);

    float y = 1.;
    float id = 0.;
    for (int i = -1; i <= 1; i++)
    for (int j = -1; j <= 1; j++)
    {
        vec2 c = vec2(i,j);
        vec2 delta = c-f+hash2f(p+c);
        float dist = dot(delta,delta);
        y = min(dist, y);
    }
    y = sqrt(y);
    return y;
}

vec2 triplanar_uv(vec3 p)
{
    return (p.xz + p.xy + p.yz)/3.;
}

float select_top_plane(vec3 p)
{
    return step(0.5, dot(p, vec3(0.,1.,0.)));
}

float sdf_water(vec3 p, vec3 s)
{
    vec3 q = abs(p)-s;
    float y_offset = - water_y(p.xz)*.20; 
    if (abs(p.x) <= s.x && abs(p.z) <= s.z)
        return q.y - y_offset;
    return max(q.x, max(q.y-y_offset, q.z));
}

float sdf_scene(vec3 p, out float m, out vec2 flag_uv)
{
    float dm = 0.;
    vec2 dm2 = vec2(0.);
    float water = sdf_water(p, vec3(1.25, 0.5, 1.25));
    water = max(-boat(p-BOAT_POS,false, dm, dm2), water);
    m = 0.;

    float boat = boat(p-BOAT_POS, true, m, flag_uv);
    if (water < boat)
        m = 0.;
    float s = min(boat, water);
    return s;
}

float sdf_scene(vec3 p)
{
    float m = 0.;
    vec2 flag_uv = vec2(0.);
    return sdf_scene(p, m, flag_uv);
}

float march(vec3 p, vec3 d, float side, out float m, out vec2 flag_uv)
{
    float y = 0.;
    for (int i =0; i < 100; i++)
    {
        float sd = sdf_scene(p, m, flag_uv)*side;
        p += d*sd;
        y += sd;
        if (sd <= 0.001 || sd >= 100.) break;
    }
    return y;
}

vec3 normal(vec3 p)
{
    vec2 e = vec2(0.01, 0.);
    float d = sdf_scene(p);
    return normalize(
        d-vec3(
            sdf_scene(p-e.xyy),
            sdf_scene(p-e.yxy),
            sdf_scene(p-e.yyx)
        )
    );
}

vec3 sky(vec3 p)
{
    float t = normalize(p).y-.25;
    vec3 top = vec3(1.0, 1.0, 0.2667);
    vec3 mid = vec3(0.9412, 0.3294, 0.2745);
    return mix(mid, top, 1.-t*t);
}

vec3 water_material(vec3 p, vec3 n, vec3 lpos, vec3 r, vec3 reflectdir)
{
    float t = u_time*.1;

    float ff = 10.;
    vec2 vuv = triplanar_uv(p)*5.;
    vuv = floor(vuv*ff)/ff;
    float foam = voronoi(vuv);
    foam = smoothstep(0.2, 1.0, foam)*3.;

    vec3 tol = -LDIR;
    float yp = step(0.5, dot(n, vec3(0.,1.,0.)));
    float a = max(0., dot(n, tol));
    float s = pow(max(0., dot(reflect(LDIR,n), -r)), 1.);
    vec3 clr = mix(
        vec3(0.32, 0.573, 0.68),
        vec3(0.75, 0.85, 0.92),
        foam * yp
    );

    // beer's law
    vec3 rd = r;
    float mat = 0.;
    vec2 flag_uv = vec2(0.);
    float ed = march(p-n*0.01, rd, -1., mat, flag_uv);
    vec3 absorption_clr = sky(normalize(rd));
    vec3 bc = exp(-absorption_clr*ed);
    clr *= bc; 

    // clr *= a;
    vec3 skyclr = sky(vec3(0., 1., 0.));
    clr = mix(clr,  vec3(1.), s*.5);
    return clr;
}

vec3 boat_material(vec3 p, vec3 n, vec3 r)
{
    vec3 rp = transform_boat(p);
    float planks = max(step(0.5, fract(rp.z*10.)), dot(n, vec3(0., 1., 0.)));

    float rand = hash2f(floor(triplanar_uv(p)*50.))*.5+.5;

    float dm = 0.; // dummy material
    vec2 dm2 = vec2(0.);
    // shitty ambient occlusion
    float sd = smoothstep(0., .05, boat(p+n*0.1-BOAT_POS, true, dm, dm2));

    vec3 clr = mix(
        vec3(0.33, 0.172, 0.262)*1.5, 
        vec3(0.4, 0.302, 0.302)*1.5, 
        planks*rand*sd
    );

    vec3 tol = LDIR;
    float a = max(0.75, dot(tol, n));
    float s = max(0., dot(reflect(r,n), tol));
    vec3 sc = sky(p);

    return mix(clr, sky(p), 1.-a)*sd+LCOLOR*s; 
}

vec3 flag_material(vec3 p, vec3 n, vec3 r, vec2 uv)
{
    float s = pow(max(0., dot(reflect(LDIR, n), -r)), 1.);
    float ss = snoise(p.yz*100.)*.85; 
    s *= ss*ss;

    vec3 f = flag_texture(uv);

    vec3 cloth_clr = mix(f, vec3(0.9, 0.9, 0.8), s);
    return cloth_clr;
}

vec3 lookat(vec3 p, vec3 l, vec2 uv, float fov)
{
    vec3 fwd = normalize(l-p);
    vec3 right = cross(vec3(0.,1., 0.), fwd);
    vec3 up = cross(fwd, right);
    return normalize(
        right*uv.x + up*uv.y + fwd*radians(fov)
    );
}

out vec4 fragColor;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv.x *= u_resolution.x / u_resolution.y;
    uv = (uv-.5)*2.;

    float rt = u_time*.25;
    // rt = 0.;
    vec3 cp = vec3(cos(rt)*3., 2., sin(rt)*3.);
    vec3 cd = lookat(cp, vec3(0.), uv, 60.);

    float mat = 2.;
    vec2 flag_uv = vec2(0.);
    float t = march(cp, cd, 1., mat, flag_uv);

    vec3 p = cp + cd*t;
    vec3 color = sky(p);
    if (t < 100.)
    {
        vec3 n = normal(p);
        vec3 l = vec3(-1., 2., -2.);

        if (mat == 0.)
        {
            float a = max(0.25, dot(normalize(l-p), n));
            color = water_material(p, n, l, cd, reflect(normalize(cd), n));
        }
        else if (mat == 1.)
        {
            color = boat_material(p, n, cd);
            color *= max(0.55555, dot(LDIR, n));
        }
        else
        {
            color = flag_material(p, n, cd, flag_uv);
        }
    }
    fragColor = vec4(color, 1.0);
}