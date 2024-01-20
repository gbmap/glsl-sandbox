
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


float cylinder(vec3 p, vec3 pos, float h, float r)
{
    /*vec3 a = pos;
    vec3 b = pos+vec3(0.0, 1.0, 0.0)*h;
    
    vec3 ap = p-a;
    vec3 ab = b-a;
    
    float t = dot(ap, ab) / dot(ab, ab);
    return length(p-(a+ab*t)) - r;*/
   
    // pontos inicial e final
    vec3 a = pos;
    vec3 b = pos+vec3(0.0, 1.0, 0.0)*h;
   
    // vetores que vão de A-P e A-B;
    vec3 ap = p-a;
    vec3 ab = b-a;
    
    // pega-se a projeção de AP em AB e divide pela projeção de AB em AB, para termos um T normalizado.
    // Isso resulta num valor escalar que vai de 0, quando P está na mesma altura de A,
    // até 1, na altura de B. Como o valor aqui não foi limitado, o que temos agora
    // é um cilindro infinito. P acima de A < 0, P acima de B > 1.
    float t = dot(ap, ab) / dot(ab, ab);
    
    // Cria-se um vetor dentro da linha AB.
	vec3 pt = a+ab*t;
    
    // distancia em y das extremidades do cilindro:
    // aqui, pega-se a distância normalizada, e muda-se ela para
    // conter valores negativos quando dentro da altura do cilindro,
    // e positivos quando fora. T inicialmente de 0 a 1, é translacionado até
    // o domínio de -0.5 a 0.5, calcula-se seu valor absoluto (0.5 a 0 a 0.5)
    // e então subtrai-se 0.5 desse valor, resultando no campo (0 a -0.5 a 0)
    float y = (abs(t-0.5)-0.5) * length(ab);
    
    // a distância em XZ do cilindro, como a distância de uma esfera onde Y é inexistente.
    float x = length(p-pt)-r;
    
    // calcula-se a distância exterior, 
    // limitando valores < 0 a == 0, e calculando pitágoras, 
    // ou a magnitude do vetor resultante.
    float e = length(max(vec2(x, y), 0.0));
    
    // distância interior, calcula-se a maior das distâncias X ou Y,
    // e limita-se a valores menores que 0
    float i = min(max(x, y), 0.0);
    
    return e+i;
}

float sdf_cube(vec3 p, vec3 sz) {
    vec3 q = abs(p) - sz;
    return length(max(q, vec3(0.))) + min(max(q.x, max(q.y,q.z)), 0.);
}

float sdf_bar(vec3 p) 
{
    // p.xz *= 1. - p.y*0.1;
    p.z += abs((p.x*p.x)*0.05);
    vec3 sz = vec3(4., 2., 1.5);

    float sza = 1.0;

    // main cube
    vec3 maincube_offset = vec3(0., -sz.y*(1.-sza), 0.); 
    p -= maincube_offset; 
    float d = sdf_cube(p, sz*sza);



    // // front detail
    float detail1sz_z = 0.10*sza;
    float detail1sz_minus = 0.4*sza;
    float detail1 = sdf_cube(
        p+vec3(0., 0., sz.z*sza+detail1sz_z), 
        vec3(sz.x*sza-detail1sz_minus, sz.y*sza-detail1sz_minus, 0.1)
    );
    d = min(d, (detail1 - .05));

    p+= maincube_offset;

    // // top table
    float top_height = 0.1*sza;
    float top_excess = 1.0*sza;
    float detailTop = sdf_cube(
        p-vec3(0., sz.y*sza-(sz.y*(1.-sza))+top_height, 0.),
        vec3(sz.x*sza+top_excess*.5, top_height, sz.z*sza+top_excess*.5)
    );
    d = min(d, detailTop);

    return d;
}

float sdf_estante(vec3 p, vec3 sz)
{
    float base = max(
        -sdf_cube(p, vec3(sz.x-0.25, sz.y-0.25, sz.z*1.1)),
        sdf_cube(p, sz)
    );
    float d = base;

    const int prateleiras = 5;
    for (int i = 1; i < prateleiras; i++) 
    {
        float y = ((sz.y*2.)/float(prateleiras))*float(i);

        float ph = 0.1;
        float pz_minus = 0.2;
        float prateleira = sdf_cube(
            p - vec3(0., -sz.y + y, 0.), 
            vec3(sz.x, ph, sz.z-pz_minus)
        );

        d = min(d, prateleira);
    }

    float tras = sdf_cube(p-vec3(0., 0., sz.z-0.05), vec3(sz.x, sz.y, 0.05));
    d = min(d, tras);

    // return sdf_cube(p, vec3(1.));
    return d;
}

float sdf_table(vec3 p)
{
    float base = cylinder(p, vec3(0.0, 0.1, 0.), 0.1, 2.); 

    float t = base;
    const int im = 4;
    for (int i = 0; i < im; i++) {
        float a = radians(float(i)*(360./float(im)));
        float c = cos(a);
        float s = sin(a);

        mat3 r = mat3(
            c, 0, s,
            0, 1, 0,
            -s, 0, c
        );

        p = p*r;

        vec3 p_perna = p + vec3(p.y*.5, 0., 0.);
        float perna = cylinder(p_perna, vec3(0.0, 0.1, 0.), -3.0, 0.1);
        t = min(t, perna);
    }

    return min(base, t);
}

vec4 sdf_scene(vec3 p)
{
    float m = 0.;
    float d = 999.;
    float plane = p.y+3.0;
    d = min(d, plane);
    m = step(plane, 100.)*1.;

    float table = sdf_table(p);
    // table = 999.0;
    // table = sdf_cube(p, vec3(1., 1., 1.));
    m = mix(m, 2., step(table,plane));

    d = min(plane, table);
    // float d = plane;

    float bar = sdf_bar(p - vec3(2.5, -2.0, 10.));
    m = mix(m, 3., step(bar, d));
    d = min(d, bar);

    float estante = sdf_estante(p - vec3(5., 1.1, 15.0), vec3(5., 4., 1.));
    d = min(d, estante);

    return vec4(d, m, 0., 0.);
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

vec3 m_color(float t, vec3 n, vec3 p)
{
    // return n;
    vec3 clr = vec3(0.);
    clr = mix(clr, vec3(0.2627, 0.2275, 0.2745), step(0.5, t));
    clr = mix(clr, vec3(0.7137, 0.2039, 0.2039), step(1.5, t));
    clr = mix(clr, vec3(0.302, 0.1725, 0.1333), step(2.5, t));
    return clr;
}

vec3 albedo(vec3 clr, vec3 p, vec3 n, vec3 lpos)
{
    vec3 ldir = normalize(lpos - p);
    float ndotl = max(0.25, dot(ldir, n));
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
        if (a <= 0.001 || a >= 100.) break;
    }
    return sdf;
}

float shadow(vec3 p, vec3 n, vec3 lpos)
{
    vec3 dir = normalize(lpos-p);
    float d = march(p+n*0.2, dir);
    return min(clamp(0., 1., step(8., d)+0.4),
           clamp(d/length(lpos-p), 0., 1.));
}

vec3 camera_direction(vec3 p, vec2 uv, vec3 look, float fov)
{
    vec3 dir = normalize(look - p);

    vec3 fwd = dir;
    vec3 right = cross(vec3(0., 1., 0.), fwd);
    vec3 up = cross(fwd, right);

    return normalize(right * uv.x + up * uv.y + fwd * fov);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv.x *= u_resolution.x / u_resolution.y;
    uv -= vec2(0.5);
    uv *= 2.;

    float cx = ((u_mouse.x/u_resolution.x)*2.-1.)*7.;
    float cy = ((u_mouse.y/u_resolution.y)*2.-1.)*7.;
    cy = max(-2.0, cy);

    vec3 cpos = vec3(0., 0., -1.);
    cpos.xy += vec2(cx, cy);
    // vec3 cpos = vec3(cx, cy, -10.00);


    float sdf = 100.;

    vec3 rpos = cpos;
    // vec3 rdir = normalize(vec3(uv, 1.0) + vec3(0., -0.5, 0.));
    vec3 rdir = camera_direction(
        cpos, uv, vec3(5., 1.1, 15.0), 1.0
    );
    // for (int i = 0; i < N_STEPS; i++)
    // {
    //     float a = sdf_scene(rpos).x;
    //     rpos += rdir * a;
    //     sdf = a;
    //     if (a <= 0.01 || a >= 100.) break;
    // }

    float d = march(rpos, rdir);
    rpos = rpos + rdir*d;

    vec3 n = normal(rpos);
    vec4 scene = sdf_scene(rpos);

    float sdfshadow = shadow(rpos, n, vec3(3., 3., 0.));

    vec3 color = m_color(scene.y, n, rpos);
    color = albedo(color, rpos, n, vec3(3., 3., -6.5));
    color *= sdfshadow;
    // color = n;
    // color = vec3(d,d,d)/30.;
    
    // color = mix(n, vec3(0.), clamp(scene.x,0.,1.));
    gl_FragColor = vec4(color, 1.);
    // gl_FragColor = vec4( pow(color,vec3(1./2.2)) , 1 );
}