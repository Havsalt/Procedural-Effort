extends MultiplayerSynchronizer


func _enter_tree() -> void:
	set_multiplayer_authority(Globals.multiplayer_authority)
