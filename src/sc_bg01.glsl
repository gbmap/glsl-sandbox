#extension GL_OES_standard_derivatives : enable

/* Main function, uniforms & utils */
#ifdef GL_ES
    precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

// #define u_time 2.0

#define E               2.7182818284

vec2 complex_exp(vec2 z)
{
    // e^x * cos(y) + i*e^x*sin(y)
    float ex = pow(E, z.x);
    return vec2(
        ex * cos(z.y),
        ex * sin(z.y)
    );
}

vec2 tile(vec2 uv, float t) {
    return fract(uv * t);
}

vec2 remap_to0(vec2 uv) {
    return uv*2.-1.;
}

vec2 complex_map(vec2 uv, float factor, vec2 c)
{
    return complex_exp(uv) + complex_exp(c);
}

vec2 to_polar(vec2 uv) {
    return vec2(
        length(uv),
        atan(uv.y, uv.x)
    );
}

float grid(vec2 uv, float t) {
    vec2 ss = step(0.05, fract(uv*t));
    return 1.-(ss.x*ss.y);
}

vec3 pattern_lights(vec2 uv, vec2 c, float zoom) {
    vec2 p = tile(uv, zoom);
    p = abs(remap_to0(p));
    p = complex_exp(p) + complex_exp(c);
    return vec3(p, pow(abs(p.x), abs(p.y)));
}

vec3 render(vec2 uv)
{
    float t = (sin(u_time)*.25 + cos(u_time)*.5)*.5;
    t = 0.5;
     
    uv = to_polar(to_polar(to_polar(uv)-.5)*.5);
    uv += u_time*.0625;

    float f = 3.0;
    vec2 cc = u_mouse/u_resolution;
    cc = vec2(.5);
    vec3 c = pattern_lights(uv, cc, f);

    vec3 clr = mix(
        vec3(sin(u_time+c.z), 0.6667, 0.302),
        vec3(0.6078, cos(u_time+c.y), 0.3333),
        c.x*c.y
    );
    return clr;
}

float dist(vec2 uv)
{
    vec3 clr = render(uv);
    float tt = length(clr);
    return tt;
}


void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv.x *= u_resolution.x/u_resolution.y;
    uv = 1.-uv;
    uv.x += 0.15;

    vec2 center = vec2(.45, .25);

    float rt = -length(uv-center)*0.5;
    mat2 m = mat2(cos(rt), -sin(rt), sin(rt), cos(rt));
    uv = m*uv;


    vec3 clr = render(uv);
    float d = dist(uv);

    vec3 duv = vec3(dFdx(uv.x), dFdy(uv.y), 0.);
    vec2 n = vec2(
        normalize(d - vec2(
            dist(uv + duv.xz),
            dist(uv + duv.yz)
        ))
    );
    float albedo = dot(n, vec2(cos(u_time), sin(u_time)));
    float spec = max(0., dot(n, uv));

    // vec3 cr = mix(vec3(0.), vec3(1.), clr*albedo);
    vec3 cr = clr*albedo;
    cr *= 0.005 + pow(length(uv-center), 2.0);
    gl_FragColor = vec4(cr, 1.0);
}
