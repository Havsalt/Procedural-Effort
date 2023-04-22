shader_type canvas_item;

uniform vec4 color : source_color;

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	if (original.a == 0.0) {
		COLOR = original;
	} else {
		COLOR = color;
	}
}
