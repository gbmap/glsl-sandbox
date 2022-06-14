/* Main function, uniforms & utils */
#ifdef GL_ES
    precision mediump float;
#endif

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

float sdf_scene(vec3 p) 
{
    return length(p - vec3(0.)) - 1.;
}

vec3 ray_dir(vec2 uv, vec3 pos, vec3 look_at) 
{
    vec3 up = vec3(0., 1., 0.);
    vec3 fwd = normalize(look_at - pos);
    vec3 right = normalize(cross(up, fwd));
    up = normalize(cross(fwd, right));

    float fov = 2.0;
    vec3 ray_dir = normalize(right*uv.x+up*uv.y+fwd*fov);
    return ray_dir;
}

void main()
{
    vec2 uv = gl_FragCoord.xy/u_resolution.xy;
    uv = uv*2.-1.;

    vec3 cpos = vec3(0., 0., 10.);
    vec3 cdir = ray_dir(uv, cpos, vec3(0.,0.,0.));
    
    vec3 p = cpos;
    float d = 0.0;
    for (int i = 0; i < 255; i++) {
        p += cdir*d;
        d += sdf_scene(p);
        if (d < 0.0001 || d > 100.) break;
    }

    vec3 color = vec3(d/100.);

    gl_FragColor = vec4(color, 1.);
}