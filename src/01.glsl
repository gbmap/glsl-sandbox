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

float sdf_head(vec3 p)
{
    return length(p)-1.;
}

float sdf_box(vec3 p, vec3 s)
{
    vec3 q = abs(p)-s;
    return max(q.x, max(q.y, q.z));
}

float sdf_scene(vec3 p)
{
    // p.z = -p.z;
    // p.x = abs(p.x);
    // p.z += clamp((p.y-.6)*p.y, 0., 1.);
    // p.x += sin(p.y*2.)-cos(p.y+TWO_PI);

    float d = 999.;
    for (int i = 0; i < 4; i++)
    {
        float bh = 1.;
        float bw = 1./float(i+1);

        vec3 p2 = p;
        p2.xz += p.y*p.y*-sign(p.xz)*.2/(float(i+1)*3.);
        d = min(d, sdf_box(p2-vec3(0.,bh*float(i),0.), vec3(bw,bh,bw)));
    }

    
    return d/1.1;
}

float march(vec3 p, vec3 d)
{
    float y = 0.;
    for (int i =0; i < 100; i++)
    {
        float sd = sdf_scene(p);
        p += d*sd;
        y += sd;
        if (sd <= 0.001 || sd >= 100.) break;
    }
    return y;
}

vec3 normal(vec3 p)
{
    vec2 e = vec2(0.01, 0.);
    float d = sdf_scene(p);
    return normalize(
        d-vec3(
            sdf_scene(p-e.xyy),
            sdf_scene(p-e.yxy),
            sdf_scene(p-e.yyx)
        )
    );
}

vec3 lookat(vec3 p, vec3 l, vec2 uv, float fov)
{
    vec3 fwd = normalize(l-p);
    vec3 right = cross(vec3(0.,1., 0.), fwd);
    vec3 up = cross(fwd, right);
    return normalize(
        right*uv.x + up*uv.y + fwd*radians(fov)
    );
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv.x *= u_resolution.x / u_resolution.y;
    uv = uv*2.-1.;


    vec2 m = ((u_mouse/u_resolution)*PI);
    float ds = 3.+m.y;
    vec3 cp = vec3(-cos(m.x)*ds, 0.5, -sin(m.x)*ds);
    vec3 cd = lookat(cp, vec3(0.), uv, 30.);

    float t = march(cp, cd);
    vec3 color = vec3(0.);

    vec3 p = cp + cd*t;
    if (t < 100.)
    {
        vec3 n = normal(p);
        color = normal(p);

        vec3 l = vec3(-1., 1., -2.);
        vec3 dl = normalize(l-p);
        float a = max(0.25, dot(dl, n));
        float s = pow(max(0., dot(reflect(-dl,n), -cd)),20.);
        color = vec3(1.)*a + vec3(1.,1.,1.)*s;
    }

    gl_FragColor = vec4(color, 1.0);
}