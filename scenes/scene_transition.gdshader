shader_type canvas_item;

uniform vec4 circle_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outer_radius : hint_range(0.0, 2.0) = 0.0;
uniform float inner_radius : hint_range(0.0, 2.0) = 0.0;
uniform float aspect_ratio = 1.0;

void fragment() {
	// Center the UV coordinates and adjust for screen aspect ratio
	vec2 uv = UV - vec2(0.5);
	uv.x *= aspect_ratio;
	
	// Calculate distance from the center
	float dist = length(uv);
	
	// Use step() for a perfectly sharp, hardline edge
	float outer = 1.0 - step(outer_radius, dist);
	float inner = step(inner_radius, dist);
	
	COLOR = circle_color;
	// The alpha is only solid between the inner and outer radius
	COLOR.a *= outer * inner;
}