
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

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float sqr(vec2 uv, vec2 sz)
{
    vec2 q = abs(uv)-sz;
    return max(q.x, q.y);
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv = uv*2.-1.;

    // float sqr = smoothstep(0.0, 1.0, uv.x);
    uv *= .75;

    vec2 skull_uv = uv;
    skull_uv.y *= clamp(0., 2., uv.y*5.);
    float skull = length(skull_uv)-.25;
    float jaw = sqr(uv-vec2(0., -0.175), vec2(0.15, 0.125)); 

    vec2 teeth_uv = uv-vec2(0.0125,0.);
    teeth_uv *= 20.;
    teeth_uv.x = fract(teeth_uv.x);
    teeth_uv -= vec2(0., -6.);
    float teeth = sqr(teeth_uv-vec2(.1,0.2), vec2(0.25, 0.5)); 
    
    float t = opSmoothUnion(skull, jaw, 0.05);
    t = max(-teeth, jaw);
    t = opSmoothUnion(t, skull, 0.05);

    float rt = radians(-45.);
    mat2 r = mat2(cos(rt), -sin(rt), sin(rt), cos(rt));

    vec2 eyes_uv = uv;
    eyes_uv.x = abs(eyes_uv.x);
    eyes_uv= r*eyes_uv;
    eyes_uv.x*=1.5;
    float eyes = length(eyes_uv-vec2(0.2,0.)) - 0.1;

    vec2 nose_uv = uv-vec2(0., -0.16);
    nose_uv.x = abs(nose_uv.x);
    nose_uv = r*nose_uv;
    nose_uv.x *= 1.2;
    float nose = length(nose_uv - vec2(0.03, 0.))-0.01;
    eyes = min(nose, eyes);
    t = max(-eyes, t);

    vec2 bone_end_uv = uv;
    bone_end_uv = r*bone_end_uv;
    bone_end_uv = abs(bone_end_uv);
    bone_end_uv = abs(bone_end_uv-vec2(0.085, 0.45));
    bone_end_uv = pow(bone_end_uv,vec2(1.275));

    float b1 = length(bone_end_uv);
    bone_end_uv = r*r*bone_end_uv;
    float b2 = length(bone_end_uv);
    float bone_end = min(b1,b2)-0.05;

    vec2 bone_uv = uv;
    float bone = sqr(r*bone_uv, vec2(0.1, 0.4));

    // t = min(bone_end, bone);
    // t = min(t, )
    // t = bone_end;

    t = 1.-step(0., t);
    vec3 color = vec3(
        t,t,t
    );

    gl_FragColor = vec4(color, 1.0);
}