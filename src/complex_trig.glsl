#version 300 es
precision highp float;

uniform vec2 u_resolution;
out vec4 fragColor;

vec2 complex_sin(vec2 z)
{
    return vec2(
        sin(z.x)*cosh(z.y),
        cos(z.x)*sinh(z.y)
    );
}

vec2 complex_cos(vec2 z)
{
    return vec2(
        cos(z.x)*cosh(z.y),
        sin(z.x)*sinh(z.y)
    );
}

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;
    uv = uv*2.0-1.0;
    uv *= 5.0;

    float t = length(complex_sin(uv));
    fragColor = vec4(vec3(fract(t)), 1.0);
}
