
/* Main function, uniforms & utils */
#ifdef GL_ES
    precision highp float;
#endif

#define TWO_PI 3.141592*2.
#define N_ITERATIONS 500
#define INFINITY 99999.

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

vec2 complex_mult(vec2 a, vec2 b)
{
    return vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x);
}

vec2 fc(vec2 z, vec2 c)
{
    return complex_mult(z, z) + c;
}

void main()
{
    vec3 color = vec3(0.);

    vec2 uv = gl_FragCoord.xy / u_resolution.xy; 
    uv = (uv-0.5)*2.;
    uv.x *=  u_resolution.x / u_resolution.y;
    uv /= u_time*u_time;
    //uv += vec2(-0.909, -0.275);

    vec2 z = vec2(-0.219, -0.275);
    //z = vec2(0.,0.);
    vec2 c = uv-vec2(TWO_PI/10., 0.4);
    int it = 0;
    float t = 0.;
    float dt = 1./float(N_ITERATIONS);
    for (int i = 0; i < N_ITERATIONS; i++) {
        it = i;
        z = fc(z, c);
        t += dt;
        if (length(z) >= INFINITY/5.) break;
    }
//float t =1.-clamp(length(z)/9999., 0., 1.);
    //float t = float(it)/float(N_ITERATIONS); 
    //vec3 clr = vec3(t, t, t);
    t = clamp(t, 0., 1.);
    vec3 clrA = mix(
        vec3(0.9882, 0.5608, 0.0), 
        vec3(0.0431, 0.2235, 0.949), 
        t
    );

    vec3 clrB = mix(
        vec3(0.2392, 0.8275, 0.0902), 
        vec3(0.7961, 0.0431, 0.949), 
        t
    );

    float cv = float(length(z) >= INFINITY);
    vec3 clr = mix(clrA, clrB, cv);
    //clr = clrB;




    gl_FragColor = vec4(clr, 1.);
}