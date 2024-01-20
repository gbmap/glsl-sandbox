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

float hash2f(vec2 x)
{
    return fract(sin(dot(x, vec2(12.783, 4.573)))*99999.55);
}

float noise(vec2 x)
{
    vec2 id = floor(x);
    vec2 f = fract(x);

    vec2 e = vec2(1., 0.);
    float a = hash2f(id);
    float b = hash2f(id+e.xy);
    float c = hash2f(id+e.yx);
    float d = hash2f(id+e.xx);
    
    float y = mix(
        mix(a, b, f.x),
        mix(c, d, f.x),
        f.y
    ); 
    return y;
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

float nebulasmoke(vec2 uv)
{
    float a = 8.;
    float ut = 0.1;
    float uva = 1.;
    float t = 1.;
    for (int i = 0; i < 3; i++)
    {
        float rt = sin(ut*u_time+uv.x*PI_TWO*uva)*radians(10.);
        mat2 r = mat2(cos(rt), -sin(rt), sin(rt), cos(rt));
        t *= a*pNoise(r*uv-vec2(u_time*ut,0.), 16);

        a*=.5;
        ut*=2.;
        uva*=2.;
    }
    return t;
}


out vec4 fragColor;
void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution.xy;
    float t = nebulasmoke(uv);
    vec3 c = vec3(0.2, 0.67, 0.3);
    vec3 color = mix(c, c, t)*t;
    color = c*t;
    fragColor = vec4(color, 1.0);
}