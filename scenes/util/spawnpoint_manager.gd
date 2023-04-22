class_name SpawnpointManager
extends Node


@onready var spawnpoints: Array[Node] = get_children()


func on_respawn_requested(from: Player) -> void:
	prints("Player", from.name, "requested respawn")
	var remaining = spawnpoints.duplicate()
	var spawnpoint: Spawnpoint = remaining[randint(0, spawnpoints.size() -1)]
	remaining.erase(spawnpoint)
	while not spawnpoint.is_active() and remaining:
		spawnpoint = remaining[randint(0, remaining.size() -1)]
		remaining.erase(spawnpoint)
	# fallback
	if not spawnpoint.is_active() and not remaining.is_empty(): # broke because no respawn ready
		from.global_position = Vector2.ZERO # spawn in center of the world
		return
	# process on succsess
	prints("Found point", spawnpoint.name)
	spawnpoint.respawn_player(from)


func randint(a: int, b: int) -> int:
	if (b - a +1) == 0:
		return a
	return randi() % (b - a +1) + a
