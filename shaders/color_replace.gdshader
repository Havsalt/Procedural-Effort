shader_type canvas_item;

uniform vec4 target : source_color;
uniform vec4 color : source_color;

void fragment() {
	vec4 original = texture(TEXTURE, UV);
	if (original == target) {
		COLOR = color;
	} else {
		COLOR = original;
	}
}
