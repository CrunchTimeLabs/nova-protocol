shader_type canvas_item;
// Planeta esférico: superficie de ruido que gira, cráteres, terminador de luz y halo de atmósfera.
// El rectángulo debe ser cuadrado; el disco ocupa `disc` de su radio y el resto es halo.

uniform vec3 surface : source_color = vec3(0.78, 0.31, 0.16);
uniform vec3 dark : source_color = vec3(0.47, 0.16, 0.09);
uniform vec3 atmosphere : source_color = vec3(1.0, 0.55, 0.35);
uniform float disc = 0.78;
uniform float spin = 0.02;
uniform float seed = 1.0;
uniform float glow_strength = 1.0;
uniform vec2 light_dir = vec2(-0.6, -0.45);

float hash(vec2 p) {
    return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
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
        p *= 2.1;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 p = (UV - 0.5) * 2.0 / disc;
    float r = length(p);
    if (r > 1.0) {
        float halo = smoothstep(1.0 / disc, 1.0, r);
        float rim = pow(1.0 - clamp((r - 1.0) / (1.0 / disc - 1.0), 0.0, 1.0), 2.5);
        COLOR = vec4(atmosphere * glow_strength * 1.3, rim * 0.55 * (1.0 - halo * 0.2));
    } else {
        vec3 n = vec3(p, sqrt(1.0 - r * r));
        float longitude = atan(n.x, n.z) + TIME * spin;
        float latitude = asin(n.y);
        vec2 map = vec2(longitude * 2.0, latitude * 2.0);
        float land = fbm(map * 1.6);
        float detail = fbm(map * 6.0 + 3.0);
        vec3 color = mix(dark, surface, smoothstep(0.3, 0.7, land));
        color *= 0.82 + 0.3 * detail;
        float craters = smoothstep(0.62, 0.7, noise(map * 5.0)) * 0.25;
        color *= 1.0 - craters;
        vec3 light = normalize(vec3(light_dir, 0.75));
        float diffuse = clamp(dot(n, light), 0.0, 1.0);
        float shade = 0.08 + 0.92 * smoothstep(-0.15, 0.6, diffuse);
        float fresnel = pow(1.0 - n.z, 3.0);
        color = color * shade + atmosphere * fresnel * 0.55 * glow_strength;
        float edge = smoothstep(1.0, 0.985, r);
        COLOR = vec4(color, edge);
    }
}
