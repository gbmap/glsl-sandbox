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

float hash2f(vec2 uv) {
    return fract(sin(dot(uv,vec2(12.5, 4.5)))*43753.5);
}

vec4 voronoi(vec2 uv) {
    vec2 p = floor(uv);
    vec2 f = fract(uv);

    float y = 1.;
    float id = 0.;
    for (int i = -1; i <= 1; i++)
    for (int j = -1; j <= 1; j++)
    {
        vec2 c = vec2(i,j);
        vec2 delta = c-f+hash2f(p+c);
        float dist = dot(delta,delta);
        if (dist < y)
            id = hash2f(p+c);

        y = min(dist, y);
    }
    y = sqrt(y);
    // float id = hash2f(p);
    return vec4(y, id, 0., 0.);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    
    float t = voronoi(uv*2.).x;
    vec3 color = vec3(t);

    gl_FragColor = vec4(color, 1.0);
}