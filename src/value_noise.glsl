
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

float hash(float n)
{
    return fract(sin(n)*99999.5);
}

float hash2f(vec2 n)
{
    return fract(sin(dot(n, vec2(12.5,4.5)))*999999.5);
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

void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution.xy;
    float t = 0.;
    if (uv.x < 0.5 && uv.y > 0.5)
    {
        t = hash(uv.x);
    }
    else if (uv.x > 0.5 && uv.y > 0.5)
    {
        t = hash2f(uv);
    }
    else if (uv.x < 0.5 && uv.y < 0.5)
    {
        t = noise(uv.x*20.);
    }
    else
    {
        t = noise(uv*30.);
    }
    
    vec3 color = vec3(
        t,t,t
    );

    gl_FragColor = vec4(color, 1.0);
}