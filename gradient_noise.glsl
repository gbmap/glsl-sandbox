#version 300 es
precision mediump float;

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

#define PI_TWO			1.570796326794897
#define PI				3.141592653589793
#define TWO_PI			6.283185307179586

float hash2f(vec2 x)
{
    return fract(sin(dot(x, vec2(12.57, 4.55)))*99999.5);
}

vec2 gradient(vec2 id)
{
    return normalize(vec2(hash2f(id), hash2f(id*2.)));
}

float value_noise(vec2 x)
{
    vec2 id = floor(x);
    vec2 f = fract(x);

    vec2 e = vec2(1., 0.);
    float a = hash2f(id);
    float b = hash2f(id+e.xy);
    float c = hash2f(id+e.yx);
    float d = hash2f(id+e.xx);

    return mix(
        mix(a, b, f.x),
        mix(c, d, f.x),
        f.y
    );
}

float gradient_noise(vec2 x)
{
    vec2 id = floor(x);
    vec2 f = fract(x);

    vec2 e = vec2(1., 0.);
    float a = dot(f, gradient(id));
    float b = dot(f, gradient(id+e.xy));
    float c = dot(f, gradient(id+e.yx));
    float d = dot(f, gradient(id+e.yy));

    return mix(mix(a,b,f.x), mix(c,d,f.x), f.y);

}

float rand(vec2 c){
	return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 p, float freq ){
	float unit = 1./freq;
	vec2 ij = floor(p/unit);
	vec2 xy = mod(p,unit)/unit;
	//xy = 3.*xy*xy-2.*xy*xy*xy;
	xy = .5*(1.-cos(PI*xy));
	float a = rand((ij+vec2(0.,0.)));
	float b = rand((ij+vec2(1.,0.)));
	float c = rand((ij+vec2(0.,1.)));
	float d = rand((ij+vec2(1.,1.)));
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
		n+=amp*value_noise(p*f*2.);
		f*=2.;
		normK+=amp;
		amp*=persistance;
		if (iCount == res) break;
		iCount++;
	}
	float nf = n/normK;
	return nf*nf*nf*nf;
}

out vec4 fragColor;
void main() {
    vec2 uv = gl_FragCoord.xy/u_resolution.xy;
    uv.x *= u_resolution.x/u_resolution.y;

    vec2 grad = gradient(floor(uv*10.));
    vec3 color = vec3(grad.x, grad.y, 0.);
    color = vec3(pNoise(uv,8));
    fragColor = vec4(color, 1.0);
}