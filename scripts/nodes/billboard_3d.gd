# [TODO]: mind the culling aabb

@tool
extends MeshInstance3D


enum BillboardMode {
	DISABLED,
	ENABLED,
	Y_BILLBOARD,
}


@export var texture: Texture2D:
	get = get_texture,
	set = set_texture


@export var pixel_size: float = 0.01:
	get = get_pixel_size,
	set = set_pixel_size


@export var offset: Vector2:
	get = get_offset,
	set = set_offset


@export var flip_x: bool:
	get = get_flip_x,
	set = set_flip_x

@export var billboard_mode: BillboardMode


func _init() -> void:
	RenderingServer.frame_pre_draw.connect(force_update_texture)
	RenderingServer.frame_pre_draw.connect(force_update_pixel_size)
	RenderingServer.frame_pre_draw.connect(force_update_billboard_mode)
	RenderingServer.frame_pre_draw.connect(force_update_offset)


func get_texture() -> Texture2D:
	return texture


func set_texture(p_texture: Texture2D) -> void:
	texture = p_texture


func get_pixel_size() -> float:
	return pixel_size


func set_pixel_size(p_pixel_size: float) -> void:
	pixel_size = p_pixel_size


func get_offset() -> Vector2:
	return offset


func set_offset(p_offset: Vector2) -> void:
	offset = p_offset


func get_flip_x() -> bool:
	return flip_x


func set_flip_x(p_flip_x: bool) -> void:
	flip_x = p_flip_x


func force_update_texture() -> void:
	if not is_instance_valid(texture):
		mesh.material[&'shader_parameter/albedo_texture'] = null
		return

	var texture_size := texture.get_size()

	if texture is AtlasTexture:
		mesh.material[&'shader_parameter/uv_offset'] = texture.region.position / texture.atlas.get_size()
		mesh.material[&'shader_parameter/uv_scale'] = texture.region.size / texture.atlas.get_size()

	mesh.material[&'shader_parameter/_texture_size'] = texture_size
	mesh.material[&'shader_parameter/albedo_texture'] = texture


func force_update_pixel_size() -> void:
	mesh.material[&'shader_parameter/pixel_size'] = pixel_size


func force_update_billboard_mode() -> void:
	mesh.material[&'shader_parameter/billboard_mode'] = billboard_mode


func force_update_offset() -> void:
	mesh.material[&'shader_parameter/offset'] = offset


func force_update_flip_x() -> void:
	mesh.material[&'shader_parameter/flip_x'] = flip_x


func force_update_flip_y() -> void:
	mesh.material[&'shader_parameter/flip_y'] = flip_y
