// notes:
// we are working in "how many screens high worth of real estate should this
// sprite take on-screen. the origin of the screen is the center, the origin
// of the sprite is also the center. all transform calcs should go off this.

shader_type spatial;
render_mode cull_disabled, depth_draw_always, depth_test_disabled, skip_vertex_transform;

uniform sampler2D screen_texture : hint_screen_texture;
uniform sampler2D albedo_texture : filter_nearest, source_color;
uniform int blend_mode : hint_enum("Add", "Subtract", "Multiply");
uniform bool unshaded_;

mat4 orthographic(float left, float right, float bottom, float top, float near, float far) {
	mat4 ortho = mat4(0.0);

	ortho[0][0] = 2.0 / (right - left);
	ortho[1][1] = 2.0 / (top - bottom);
	ortho[2][2] = -2.0 / (far - near);
	ortho[3][3] = 1.0;

	ortho[3][0] = -(right + left) / (right - left);
	ortho[3][1] = -(top + bottom) / (top - bottom);
	ortho[3][2] = -(far + near) / (far - near);

	return ortho;
}

void vertex() {
	vec2 texture_size = vec2(textureSize(albedo_texture, 0));
	vec2 screen_size = vec2(textureSize(screen_texture, 0));
	mat4 projection = orthographic(-0.5, 0.5, -0.5, 0.5, 0, 1000);

	VERTEX = (projection * MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 color = texture(albedo_texture, UV);

	ALBEDO = color.rgb;
	ALPHA = color.a;
	LIGHT_VERTEX = vec3(0);
	EMISSION = mix(EMISSION, ALBEDO, float(unshaded_));

	vec4 screen_color = texture(screen_texture, SCREEN_UV);

	ALBEDO = mix(ALBEDO, screen_color.rgb + ALBEDO, float(blend_mode == 1));
	ALBEDO = mix(ALBEDO, screen_color.rgb - ALBEDO, float(blend_mode == 2));
	ALBEDO = mix(ALBEDO, screen_color.rgb * ALBEDO, float(blend_mode == 3));

	DEPTH = 1.0 - (1.0 - FRAGCOORD.z) * 0.7;
}

void light() {
	DIFFUSE_LIGHT += clamp(ATTENUATION / PI, 0.0, 1.0) * LIGHT_COLOR;
}
