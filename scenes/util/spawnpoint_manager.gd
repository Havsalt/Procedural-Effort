class_name SpawnpointManager
extends Node


@onready var spawnpoints: Array[Node] = get_children()


func on_respawn_requested(from: Player) -> void:
	prints("+ Player", from.name, "requested respawn")
	var remaining = spawnpoints.duplicate()
	var spawnpoint: Spawnpoint = remaining[randint(0, spawnpoints.size() -1)]
	remaining.erase(spawnpoint)
	while not spawnpoint.is_active() and remaining:
		spawnpoint = remaining[randint(0, remaining.size() -1)]
		remaining.erase(spawnpoint)
	# fallback
	if not spawnpoint.is_active() and not remaining.is_empty(): # broke because no respawn ready
		from.global_position = Vector2.ZERO # spawn in center of the world
		print("! Did not find point")
		return
	# process on succsess
	prints("x Found point", spawnpoint.name)
	spawnpoint.respawn_player(from)
	var spawnpoint_idx = spawnpoints.find(spawnpoint)
	rpc("remote_respawn_player", from.name, spawnpoint_idx)


func randint(a: int, b: int) -> int:
	if (b - a +1) == 0:
		return a
	return randi() % (b - a +1) + a


@rpc("reliable", "call_remote", "any_peer")
func remote_respawn_player(node_name: String, location_idx: int) -> void:
	var player = get_parent().get_node(node_name)
	var spawnpoint = spawnpoints[location_idx]
	spawnpoint.respawn_player(player)
