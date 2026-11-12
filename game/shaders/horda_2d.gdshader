// Enemigos de la horda (MultiMesh 2D): textura por color de instancia y
// destello blanco al recibir daño (INSTANCE_CUSTOM.x = 0..1).
shader_type canvas_item;

varying float v_flash;

void vertex() {
	v_flash = INSTANCE_CUSTOM.x;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	c.rgb = mix(c.rgb, vec3(1.0), clamp(v_flash, 0.0, 1.0));
	COLOR = c;
}
