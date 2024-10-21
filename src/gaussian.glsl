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

float hash(float x)
{
    return fract(sin(x) * 43758.5453123);
}

float gauss1d(float x, float mean, float sigma)
{
    x = hash(x);
    return 1./(sigma*sqrt(2.*PI))*exp(-(x-mean)*(x-mean)/(2.*sigma*sigma));
}

float gauss2d(vec2 x, vec2 mean, vec2 sigma)
{
    return gauss1d(x.x, mean.x, sigma.x) * gauss1d(x.y, mean.y, sigma.y);
}

void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution.xy;
    float t = gauss2d(uv, vec2(0.25), vec2(.5));
    vec3 color = vec3(
        t,t,t
    );

    gl_FragColor = vec4(color, 1.0);
}