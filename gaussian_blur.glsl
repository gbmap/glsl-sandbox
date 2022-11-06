#extension GL_OES_standard_derivatives : enable
/* Main function, uniforms & utils */
#ifdef GL_ES
    precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;
uniform sampler2D u_buffer0;

#define PI_TWO			1.570796326794897
#define PI				3.141592653589793
#define TWO_PI			6.283185307179586


float hash2f(vec2 x)
{
    return fract(sin(dot(x, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 x)
{
    vec2 id = floor(x);
    vec2 f = fract(x);

    vec2 e = vec2(0.,1.);
    float a = hash2f(id);
    float b = hash2f(id+e.yx);
    float c = hash2f(id+e.xy);
    float d = hash2f(id+e.yy);

    return mix(
        mix(a,b,f.x),
        mix(c,d,f.x),
        f.y
    );
}

#define S 1
#define N 4

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv.x *= u_resolution.x / u_resolution.y;

    // vec3 color = texture2D(u_buffer0, uv).xyz;
    vec3 orig_color = texture2D(u_buffer0, uv).xyz;
    vec3 color = vec3(0.);
    gl_FragColor = vec4(color, 1.0);
    for (int i = 0; i < S; i++)
    {
        float a = float(i)*length(vec2(dFdx(uv.x), dFdy(uv.y)));
        for (int j = 0; j < N; j++)
        {
            float t = (float(j)/float(N))*TWO_PI;
            vec2 o = vec2(cos(t), sin(t))*a;
            color += texture2D(u_buffer0,uv+o).xyz; 
        }
    }
    color /= float(S*N);
    // color /= (float(S)*float(N));

    if (uv.x < u_mouse.x/u_resolution.x)
        color = orig_color;
    else 
        color = orig_color+color*length(orig_color)*.4;


    gl_FragColor = vec4(color, 1.0);
}