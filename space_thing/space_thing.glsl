#version 300 es
precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

#define CPOS vec3(0.675, -0.65, -1.85)*1.5
#define LOOKAT vec3(-1.75, -0.1, 0.)
#define PI 3.1415926535897932384626433832795
#define PI_TWO 6.28318530718
#define LPOS vec3(-0.5, 2., -1.)*1.5
#define LPOS2 vec3(2.5, 1., 5.0)
#define LCLR2 vec3(0.96,0.623*1.2,0.433*1.2) 
#define CLR_AMBIENT vec3(0.129, 0.01, 0.115)*.5

float sdf_box(vec3 p, vec3 s)
{
    vec3 q = abs(p)-s;
    return length(max(q, 0.))+min(max(q.x,max(q.y,q.z)),0.);
}

float sdf_octahedron(vec3 p, float s)
{
    p = abs(p);
    return (p.x+p.y+p.z-s)*0.578;
}

float sdf_scene(vec3 p)
{
    p*=.25;
    p-= vec3(-0.85, .15, -0.45 );
    float t = u_time*0.125;
    mat3 r_sph = mat3(
        cos(t), 0., sin(t),
        0., 1., 0.,
        -sin(t), 0., cos(t)
    );
    mat3 r_oct = mat3(
        vec3(cos(t), 0., sin(t)),
        vec3(0., 1., 0.),
        vec3(-sin(t), 0., cos(t))
    )*mat3(
        vec3(1., 0., 0.),
        vec3(0., cos(t*2.), -sin(t*2.)),
        vec3(0., sin(t*2.), cos(t*2.))
    )*mat3(
        vec3(cos(t*.5), -sin(t*.5), 0.),
        vec3(sin(t*.5), cos(t*.5), 0.),
        vec3(0., 0., 1.)
    );
    vec3 sp = r_oct*r_sph*p;
    vec2 s = vec2(.275, .75);
    float sph = max(-sdf_box(sp, s.xxy),max(-sdf_box(sp, s.yxx), max(-sdf_box(sp, s.xyx), length(sp)-.5)));
    sph = min(sph, sdf_octahedron(r_oct*p, 0.25));



    #ifdef DEBUG_LIGHT
    float l1 = length(p-LPOS)-0.5;
    float l2 = length(p-LPOS2)-0.5;
    return min(sph,min(l1, l2));
    #endif

    return sph-0.01;
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

float hash2f(vec2 p)
{
    return fract(sin(dot(p, vec2(12.55, 4.55)))*999999.5);
}

float noise(vec2 p, float freq ){
	float unit = 1./freq;
	vec2 ij = floor(p/unit);
	vec2 xy = mod(p,unit)/unit;
	xy = .5*(1.-cos(PI*xy));
	float a = hash2f((ij+vec2(0.,0.)));
	float b = hash2f((ij+vec2(1.,0.)));
	float c = hash2f((ij+vec2(0.,1.)));
	float d = hash2f((ij+vec2(1.,1.)));
	float x1 = mix(a, b, xy.x);
	float x2 = mix(c, d, xy.x);
	return mix(x1, x2, xy.y);
}

float pNoise(vec2 p, int res){
	float persistance = .5;
	float n = 0.;
	float normK = 0.;
	float f = 4.;
	float amp = 1.;
	int iCount = 0;
	for (int i = 0; i<50; i++){
		n+=amp*noise(p,f);
		f*=2.;
		normK+=amp;
		amp*=persistance;
		if (iCount == res) break;
		iCount++;
	}
	float nf = n/normK;
	return nf*nf*nf*nf;
}

float nebula_smoke(vec2 uv)
{
    float a = 8.;
    float ut = 0.01;
    float uva = 1.;
    float t = 1.;
    for (int i = 0; i < 2; i++)
    {
        float rt = sin(ut*u_time+uv.x*PI_TWO*uva)*radians(10.);
        mat2 r = mat2(cos(rt), -sin(rt), sin(rt), cos(rt));
        t *= a*pNoise(r*uv-vec2(u_time*ut,0.), 16);

        a*=.5;
        ut*=2.;
        uva*=3.;
    }
    return t;
}

float voronoi(vec2 uv)
{
    vec2 id = floor(uv);
    vec2 f = fract(uv);

    float res = 1.;
    for (int i = -1; i <= 1; i++)
    for (int j = -1; j <= 1; j++)
    {
        vec2 n = vec2(i,j);
        vec2 c = n-f+hash2f(id+n);
        res = min(res, dot(c,c));
    }
    return sqrt(res);
}

vec2 sky_uv(vec3 p)
{
    p = normalize(p);
    vec2 uv = vec2(
        atan(p.z+1.85, p.x*3.) / PI_TWO + 0.5,
        p.y * 0.5 + 0.5
    );
    return uv;
}

vec3 sky(vec2 uv, float uvz, vec3 p, float nuv, vec2 nuvo)
{
    // float uvz = 5.;
    p = normalize(p);
    float stars = 1.-voronoi(uv*uvz);
    float starsn = noise(uv*uvz, uvz) ;
    stars = pow(stars, mix(25., 200., starsn));
    stars *= noise(uv+u_time*.05, uvz);

    vec3 starcolors = vec3(1.);

    vec3 nebulacolor = mix(CLR_AMBIENT, vec3(0.67, 0.3, 0.52), pNoise(uv-vec2(u_time*.006125, 0.), 16));
    // float greennebulaf = pNoise(10.*uv+3.+u_time*0.01,16);
    float greennebulaf = nebula_smoke(nuvo+uv*nuv);
    vec3 greennebula = vec3(0.2, 0.67, 0.3);
    greennebula = mix(
        mix(
        vec3(0.2, 0.67, 0.3), 
        vec3(0.67, 0.3, 0.52),
        sin(dot(p, vec3(0.,1., 0.))*PI_TWO)*.5+.5
    ),
        vec3(0.34, 0.26, 0.67),
        sin(dot(p, vec3(cos(u_time*.1),-1., sin(u_time*.05)))*PI_TWO)*.5+.5
    );


    // return greennebula*greennebulaf;
    
    nebulacolor = mix(nebulacolor, greennebula, greennebulaf);

    vec3 skycolor = nebulacolor;
    vec3 s = mix(starcolors, skycolor, 1.-stars);


    float sunn = pNoise(uv+u_time*.1, 16)*.5;
    float sunf = max(max(0., dot(uv, normalize(vec2(2.,-1.)))+sunn),
    max(0., dot(p, normalize(vec3(1.,2.,100.)))));
    vec3 sun = LCLR2*sunf*sunf*sunf*sunf*sunf*sunf*sunf*sunf*sunf*sunf*sunf;
    s += sun;

    return s;
}

vec3 sky(vec3 p)
{
    p = normalize(p);
    vec2 uv = sky_uv(p);
    return sky(uv, 50., p, 1., vec2(-1.));
}

vec3 shading(vec3 p, vec3 r, vec3 n, float d, vec3 cpos, vec3 lpos)
{
    if (d >= 999.)
        return sky(p);
    vec3 clr = vec3(0.24, 0.21, 0.332);
    vec3 tol = lpos-p;
    vec3 ldir = normalize(tol);
    if (d <= 0.01)
    {
    #ifdef DEBUG_LIGHT
    return vec3(1.);
    #endif

        float lambert = max(0., dot(ldir, n));
        clr = mix(CLR_AMBIENT, clr,lambert);
        // clr = vec3(1.);
    }

    // ambient occlusion
    
    
    float ao = 1.;
    float ao_dist = 0.1;
    float ao_bias = 0.01;
    float ao_scale = 2.;
    float ao_intensity = 1.;
    float dd = ao_dist;
    for (int i = 0; i < 5; i++)
    {
        float hr = sdf_scene(p + n * ao_bias + r * dd);
        ao -= hr * ao_scale;
        dd += ao_dist;
    }
    ao = clamp(ao, 0., 1.);
    ao = 1.-pow(ao, ao_intensity);
    clr = mix(clr, CLR_AMBIENT, ao);

    return clr;
}

vec3 render(vec2 uv)
{
    vec3 cpos = CPOS;
    vec3 cdir = lookat(cpos, uv, LOOKAT, 0.9);

    float t = march(cpos, cdir);
    vec3 p = cpos+cdir*t;
    vec3 color = sky(uv, 25., vec3(uv.x, uv.y, 0.), .25, vec2(2.));
    float d = sdf_scene(p);
    if (d <= 0.001)
    {
        color = normal(p);
        vec3 n = normal(p);
        color = shading(p, cdir, n, t, cpos, LPOS);

        float k = 120.;

        vec3 reflp = p+n*0.01;
        vec3 refln = n;
        vec3 refldir = cdir;

        for (int i = 1; i < 4; i++)
        {
            float spec = max(0., dot(reflect(normalize(LPOS-p), n), refldir));
            color = mix(color, vec3(0.97, 0.98, 0.86)*0.8, pow(spec, 20.));

            vec3 lpos2 = LPOS2;
            float spec2 = max(0., dot(reflect(normalize(lpos2-p), n), cdir));

            color = mix(color, LCLR2, pow(spec2, 0.5));
            float reflectivity = max(0., 0.5-0.1*float(i));
            refldir = reflect(refldir, refln);
            reflp = reflp+refln*0.01;
            float refld = march(reflp, refldir);
            reflp = reflp+refldir*refld;
            refln = normal(reflp);

            vec3 reflclr = shading(reflp, refldir, refln, refld, cpos, LPOS);
            float reflnoise = noise(p.xz*2.,100.)*hash2f(p.xy);
            float reflfl = reflectivity-smoothstep(0., 1.,reflnoise)*.05;
            color = mix(color, reflclr, reflfl);


            if (refld >= 999.)
            {
                color = mix(color, sky(reflp), reflfl);
                break;
            }
        }


        
    }
    return color;
}


out vec4 fragColor;

void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution.xy;
    uv = uv*2.-1.;
    uv.x *= u_resolution.x/u_resolution.y;

    vec3 color = render(uv);

// #define AA
#ifdef AA
    vec3 duv = vec3(dFdx(uv.x), dFdy(uv.y), 0.);
    color += render(uv+duv.xz)
          + render(uv-duv.xz)
          + render(uv+duv.zy)
          + render(uv-duv.zy);
    color /= 5.;
#endif


    fragColor = vec4(color, 1.0);
    // fragColor = vec4( pow(color,vec3(1./2.2)) , 1 );
}