
/* Main function, uniforms & utils */
#ifdef GL_ES
    precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

#define PI_TWO			1.570796326794897
#define FLOORS 100

float hash2f(vec2 p){return fract(sin(dot(p, vec2(12.484842, 4.52395)))*9242482.3);}
float noise(vec2 uv)
{
    float a = 0.;
    for (int i = 0; i < 5; i++)
        a += length(max(vec2(0.), sin(fract(uv/float(i+1))*PI_TWO*2.)*hash2f(floor(uv))))/4.;
    return a;
}

vec3 v(vec2 uv)
{
    float t = 0.;
    vec3 clr = vec3(0.);
    for (int i = 10; i< FLOORS; i++)
    {
        float rt = float(i)/25.*1.;
        mat2 m = mat2(cos(rt), -sin(rt), sin(rt), cos(rt));
        t=max(t, noise(m*uv*float(i+1)*.1+u_time)*(5./float(i+1))*(1.-(float(i+1)/100.)));
        clr += vec3(sin(t)*.5, cos(t*2.), fract(tan(t*.1)))*t; 
    }
    return fract(clr)*pow(t, .125);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv.x *= u_resolution.x / u_resolution.y;
    uv = (uv*2.-1.)*3.;
    vec3 clr = v(uv);
    gl_FragColor = vec4(clr, 1.0);
}