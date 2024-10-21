// #version 300 es
#extension GL_OES_standard_derivatives : enable

/* Main function, uniforms & utils */
#ifdef GL_ES
    precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

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
    float uvz = 2.5;
    float t = voronoi(uv*uvz, u_time, .2);
    mat2 m = mat2(cos(t), -sin(t), sin(t), cos(t));
    uv = m*uv;
    return voronoi(uv*uvz, u_time*0.25, 0.5);
}

vec3 render(vec2 uv)
{
    float t0 = pattern(uv);
    vec2 n = normalize(vec2(
        pattern(uv-vec2(dFdx(uv.x)*2., 0.)),
        pattern(uv-vec2(0., dFdy(uv.y)*2.))
    ) - pattern(uv));

    vec2 lp = normalize(vec2(cos(u_time*0.5),sin(u_time*.25)));
    float s = pow(max(0., dot(uv, lp)), 1.5);
    float t = dot(n, lp)+s*.25;
    t*= t0;

    vec3 color = vec3(
        t,t,t
    );
    color = vec3(t, sin(t*2.+uv.x)*.5+.5, cos(t*2.)*.5+.5)*t;
    color.z = voronoi(color.yz, 0., 0.);
    color = mix(color, vec3(0.168, 0., 0.126)*.5, smoothstep(0., 1.25, 1.-length(color)*3.));

    return color;
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= u_resolution.x/u_resolution.y;
    uv *= 1.25;
    uv *= smoothstep(0., 0.125, length(uv))*length(uv)*1.23;

    vec3 color = render(uv);

    gl_FragColor = vec4(color, 1.0);
}