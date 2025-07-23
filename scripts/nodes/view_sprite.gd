@tool
extends Node3D


@export var texture: Texture2D
@export var pixel_size: float = 0.01

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var mesh_material_override: ShaderMaterial = mesh_instance.material_override


func _ready() -> void:
	RenderingServer.frame_pre_draw.connect(func () -> void:
		mesh_material_override.set_shader_parameter.call_deferred(&'albedo_texture', texture)
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
