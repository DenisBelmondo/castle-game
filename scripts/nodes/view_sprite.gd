@tool
extends Node3D


@export var texture: Texture2D

## A multiplier used to size the quad mesh on which the sprite is displayed.
## Hint: If you're using weapon sprites designed for a canvas of 320x240, you
## would need to set this value to 1.0/320 for pixel perfection at a
## window resolution of 320x240. Since Doom weapon sprites were technically
## designed for a 320x200 canvas stretched vertically to 320x240, you would
## need to set this value to 1/(320*(200/240)).
@export var pixel_size: float = 0.01

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var mesh_material_override: ShaderMaterial = mesh_instance.material_override


func _ready() -> void:
	RenderingServer.frame_pre_draw.connect(func () -> void:
		mesh_material_override.set_shader_parameter(&'albedo_texture', texture)
		_recalculate())


func _recalculate() -> void:
	var quad_mesh := mesh_instance.mesh as QuadMesh

	mesh_instance.visible = true

	if not is_instance_valid(texture):
		mesh_instance.visible = false
		quad_mesh.size = Vector2.ONE
		return

	var texture_size := texture.get_size()

	quad_mesh.size = texture_size * pixel_size
