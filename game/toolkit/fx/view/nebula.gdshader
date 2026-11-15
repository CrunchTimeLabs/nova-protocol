shader_type canvas_item;
// Nebulosa de fondo: ruido fractal suave que se desplaza con el paralaje del viaje.

uniform vec2 drift = vec2(0.0);
uniform vec3 tint_a : source_color = vec3(0.10, 0.05, 0.22);
uniform vec3 tint_b : source_color = vec3(0.02, 0.12, 0.22);
uniform vec3 base : source_color = vec3(0.024, 0.035, 0.07);

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p *= 2.03;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 p = UV * vec2(3.4, 2.0) + drift * 0.0006 + vec2(TIME * 0.004, 0.0);
    float a = fbm(p);
    float b = fbm(p * 1.7 + vec2(5.2, 1.3) + a);
    vec3 color = base;
    color += tint_a * smoothstep(0.45, 0.85, a) * 0.9;
    color += tint_b * smoothstep(0.5, 0.9, b) * 0.8;
    float vignette = smoothstep(1.15, 0.35, length(UV - 0.5) * 1.4);
    COLOR = vec4(color * (0.55 + 0.45 * vignette), 1.0);
}
