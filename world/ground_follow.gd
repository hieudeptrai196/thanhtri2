extends StaticBody3D
## Keeps the ground under the fortress on an endless road. Moves in whole grid steps so the
## world-space ground pattern does not visibly slide.

@export var target: Node3D
@export var grid_step: float = 10.0


func _physics_process(_delta: float) -> void:
	if target == null:
		return
	var at := target.global_position
	global_position = Vector3(snappedf(at.x, grid_step), 0.0, snappedf(at.z, grid_step))
