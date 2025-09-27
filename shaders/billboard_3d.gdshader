shader_type spatial;
render_mode cull_back, specular_disabled;

const int BILLBOARD_DISABLED = 0;
const int BILLBOARD_ENABLED = 1;
const int BILLBOARD_FIXED_Y = 2;

uniform vec2 _texture_size;

uniform sampler2D albedo_texture : filter_nearest, source_color;
uniform vec2 uv_offset;
uniform vec2 uv_scale = vec2(1);
uniform vec2 offset;
uniform bool flip_x;
uniform bool flip_y;
uniform int billboard_mode : hint_enum("Disabled", "Enabled", "Y-Billboard");
uniform float pixel_size = 0.01;

varying vec2 uv;

void vertex() {
	UV.x = mix(UV.x, 1.0 - UV.x, float(flip_x));
	UV.y = mix(UV.y, 1.0 - UV.y, float(flip_y));
	uv = UV * uv_scale + uv_offset;

	// aspect ratio
	VERTEX.xy *= _texture_size;
	VERTEX.xy += offset;

	// lmfao stupid ass solution to maintain compat with how internal sprite3d
	// works
	VERTEX *= pixel_size;

	switch (billboard_mode) {
		case BILLBOARD_ENABLED:
			MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
				MAIN_CAM_INV_VIEW_MATRIX[0],
				MAIN_CAM_INV_VIEW_MATRIX[1],
				MAIN_CAM_INV_VIEW_MATRIX[2],
				MODEL_MATRIX[3]);
			break;
		case BILLBOARD_FIXED_Y:
			MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
				vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
				vec4(0.0, 1.0, 0.0, 0.0),
				vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
				MODEL_MATRIX[3]);
			break;
	}

	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
	vec4 color = texture(albedo_texture, uv);

	ALBEDO = color.rgb;
	ALPHA = color.a;
	//LIGHT_VERTEX = vec3(0);
}

void light() {
	DIFFUSE_LIGHT += clamp(ATTENUATION / PI, 0.0, 1.0) * LIGHT_COLOR;
}
