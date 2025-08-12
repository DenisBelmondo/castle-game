extends Camera3D


@onready var animation_player: AnimationPlayer = $AnimationPlayer


func shake() -> void:
	animation_player.play(&'shake')
