class_name CameraShake2D
extends Camera2D


@export var max_trauma := 1.0
@export var trauma_power := 2.0
@export var amount := 0.0
@export var decay := 0.8
@export var max_offset := Vector2(64, 64)
@export var max_roll := 0.1

var trauma := 0.0 # current energy


func _process(delta: float) -> void:
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		amount = pow(trauma, trauma_power)
		rotation = max_roll * amount * randf_range(-1, 1)
		offset.x = max_offset.x * amount * randf_range(-1, 1)
		offset.y = max_offset.y * amount * randf_range(-1, 1)


func shake(energy: float = 0.5) -> void: # applies shake energy
	trauma = min(trauma + energy, max_trauma)


func set_shake(energy: float) -> void:
	trauma = energy
