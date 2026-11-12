// Suelo del Bosque de los Susurros en 2D (misma receta que ground_forest.gdshader):
// tierra oscura, manchas de musgo, hojas caídas y restos de baldosas, en
// coordenadas de mundo. Fuera de la arena se oscurece.
shader_type canvas_item;

uniform vec3 soil_dark : source_color = vec3(0.137, 0.094, 0.082);
uniform vec3 soil : source_color = vec3(0.27, 0.21, 0.14);
uniform vec3 moss : source_color = vec3(0.231, 0.204, 0.102);
uniform vec3 leaves : source_color = vec3(0.37, 0.17, 0.08);
uniform vec3 stone : source_color = vec3(0.416, 0.345, 0.282);
uniform float pixels_per_meter = 90.0;
uniform float tile_size = 3.0;
uniform float arena_half = 2000.0;

varying vec2 world_pos;

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
	for (int k = 0; k < 4; k++) {
		value += amplitude * noise(p);
		p *= 2.03;
		amplitude *= 0.5;
	}
	return value;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 p = world_pos / pixels_per_meter;
	vec3 color = mix(soil_dark, soil, fbm(mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * p * 0.15));

	float moss_mask = smoothstep(0.52, 0.72, fbm(p * 0.07 + 13.0));
	color = mix(color, moss, moss_mask * 0.85);

	// Coordenadas giradas para que las manchas no salgan alineadas en cuadrados.
	vec2 q = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8)) * p;
	float leaf_mask = smoothstep(0.62, 0.72, fbm(q * 1.4 + 7.0)) * smoothstep(0.45, 0.7, fbm(p * 0.05 + 3.0));
	color = mix(color, leaves * (0.8 + 0.4 * fbm(q * 3.0)), leaf_mask * 0.6);

	vec2 cell = floor(p / tile_size);
	vec2 local = fract(p / tile_size);
	float tiles_zone = smoothstep(0.6, 0.72, fbm(p * 0.035 + 50.0));
	float edge = min(min(local.x, 1.0 - local.x), min(local.y, 1.0 - local.y));
	float joint = 1.0 - smoothstep(0.01, 0.035, edge);
	vec3 tile_color = stone * (0.7 + 0.4 * hash(cell));
	float broken = step(0.18, hash(cell + 3.7));
	color = mix(color, mix(tile_color, soil_dark, joint), tiles_zone * broken * 0.85);

	// Fuera de la arena: más oscuro (límite visible sin muros todavía).
	vec2 d = abs(world_pos) - vec2(arena_half);
	float outside = smoothstep(0.0, 160.0, max(d.x, d.y));
	color *= 1.0 - 0.7 * outside;

	COLOR = vec4(color, 1.0);
}
