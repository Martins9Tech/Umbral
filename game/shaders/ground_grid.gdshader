// Suelo greybox: rejilla antialiasada en coordenadas de mundo para leer el movimiento.
shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.17, 0.21, 0.16);
uniform vec3 line_color : source_color = vec3(0.25, 0.30, 0.23);
uniform vec3 major_color : source_color = vec3(0.34, 0.40, 0.30);
uniform float cell_size = 2.0;
uniform float major_every = 5.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float grid_line(vec2 coord) {
	vec2 g = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
	return 1.0 - min(min(g.x, g.y), 1.0);
}

void fragment() {
	vec2 coord = world_pos.xz / cell_size;
	vec3 color = mix(base_color, line_color, grid_line(coord));
	color = mix(color, major_color, grid_line(coord / major_every));
	ALBEDO = color;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
