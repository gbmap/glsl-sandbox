
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
#define FLOORS 100

float y(vec2 uv)
{
    uv = fract(abs(uv));
    return 1.-step(0., length(uv)-.5);
}

vec3 v(vec2 uv)
{
    float t = 0.;
    vec3 clr = vec3(0.);
    for (int i = 10; i< FLOORS; i++)
    {
        float rt = float(i)/25.*1.;
        mat2 m = mat2(cos(rt), -sin(rt), sin(rt), cos(rt));
        t=max(t, y(m*uv*float(i+1)*.1+u_time*.2)*(5./float(i+1))*(1.-(float(i+1)/100.)));
        clr += vec3(sin(t)*.5, cos(t*2.), fract(tan(t*.1)))*t; 
    }
    return fract(clr)*pow(t, .125);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv = (uv *2.-1.)*5.;
    // uv = mod(uv, 1.);
    // float t = v(uv);
    float t = 0.;
    vec3 color = vec3(
        t,t,t
    );
    color = v(uv);

    gl_FragColor = vec4(color, 1.0);
}