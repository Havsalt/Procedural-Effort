class_name FloatPointSync
extends Marker2D


func _process(_delta: float) -> void:
	if owner.active: # `owner` has to be of type Item
		rpc("remote_set_position", position)
		rpc("remote_set_rotation", rotation)


@rpc("unreliable", "call_remote", "any_peer")
func remote_set_position(value: Vector2) -> void:
	position = value


@rpc("unreliable", "call_remote", "any_peer")
func remote_set_rotation(value: float) -> void:
	rotation = value
