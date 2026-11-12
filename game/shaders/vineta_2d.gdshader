// Viñeta suave: oscurece los bordes de la pantalla (ambiente del moodboard).
shader_type canvas_item;

uniform float strength = 0.55;

void fragment() {
	vec2 d = UV - 0.5;
	d.x *= 1.6;
	float v = smoothstep(0.35, 0.95, length(d));
	COLOR = vec4(0.05, 0.03, 0.02, v * strength);
}
