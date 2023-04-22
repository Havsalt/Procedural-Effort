shader_type canvas_item;

void fragment() {
	vec4 pattern = texture(TEXTURE, vec2(0, 0));
	vec4 original = texture(TEXTURE, UV);
	if (original == pattern) {
		COLOR = vec4(0, 0, 0, 0);
	} else {
		COLOR = original;
	}
}
