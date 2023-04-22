class_name Main
extends Node2D


const SAVE_PATH = "res:///save.cfg"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera_hold_point: Marker2D = $CameraHoldPoint
@onready var menu: CanvasLayer = $Menu
@onready var host_field: TextEdit = $Menu/PanelInfo/HBoxContainer/HostName/TextEdit
@onready var port_field: TextEdit = $Menu/PanelInfo/HBoxContainer/PortNumber/TextEdit
@onready var name_field: TextEdit = $Menu/PanelName/VBoxContainer/TextEdit
@onready var scoreboard_field : TextEdit = $Scoreboard/TextEdit
@onready var spawnpoint_manager: SpawnpointManager = $SpawnpointManager

var multiplayer_peer = ENetMultiplayerPeer.new()
var config = ConfigFile.new()
var scoreboard = {}


func _ready() -> void:
	# set platform info
	if OS.has_feature("mobile"):
		Globals.platform = "mobile"
	else:
		Globals.platform = "desktop"
	# setup
	name_field.placeholder_text = str(multiplayer_peer.generate_unique_id())
	animation_player.play("idle")
	if not OS.has_feature("mobile") and not OS.has_feature("web"): # load last used IP address
		var err = config.load(SAVE_PATH)
		if err == OK:
			host_field.text = config.get_value("last_address", "host")
			port_field.text = str(config.get_value("last_address", "port"))


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("f11"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_join_pressed() -> void:
	var host: String = host_field.text
	var port: int = port_field.text.to_int()
	# store address if possible
	if not OS.has_feature("mobile") and not OS.has_feature("web"): # save last used IP address
		config.set_value("last_address", "host", host)
		config.set_value("last_address", "port", port)
		config.save(SAVE_PATH)
	# setup peer
	multiplayer_peer.create_client(host, port)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.connection_failed.connect(func (): get_tree().change_scene_to_file(self.scene_file_path)) # reload menu
	multiplayer.server_disconnected.connect(func (): get_tree().change_scene_to_file(self.scene_file_path)) # reload menu
	multiplayer_peer.peer_disconnected.connect(func (id: int):
		get_node(str(id)).disconnect("remotely_killed", _on_remote_kill)
		get_node(str(id)).queue_free()
	)
	if name_field.text == "":
		Globals.nickname = name_field.placeholder_text
	else:
		Globals.nickname = name_field.text
	menu.hide()


func _on_host_pressed() -> void:
	var host: String = host_field.text
	var port: int = port_field.text.to_int()
	# store address if possible
	if not OS.has_feature("mobile") and not OS.has_feature("web"): # save last used IP address
		config.set_value("last_address", "host", host)
		config.set_value("last_address", "port", port)
		config.save(SAVE_PATH)
	# setup peer
	multiplayer_peer.create_server(port)
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.connection_failed.connect(func (): get_tree().change_scene_to_file(self.scene_file_path)) # reload menu
	multiplayer.server_disconnected.connect(func (): get_tree().change_scene_to_file(self.scene_file_path)) # reload menu
	multiplayer_peer.peer_disconnected.connect(func (id: int): get_node(str(id)).queue_free())
	multiplayer_peer.peer_connected.connect(func (id: int): add_player_character(id))
	if name_field.text == "":
		Globals.nickname = name_field.placeholder_text
	else:
		Globals.nickname = name_field.text
	add_player_character()
	menu.hide()


func add_player_character(id: int = 1) -> void:
	var instance: Player = preload("res://scenes/player/player.tscn").instantiate()
	instance.name = str(id)
	instance.connect("remotely_killed", _on_remote_kill)
	add_child(instance)

# local detection
func _on_remote_kill(victim: String, killer: String) -> void:
	rpc("remote_kill_detected", victim, killer)
	increase_scoreboard_for(killer)

# remote detection
@rpc("reliable", "call_remote", "any_peer")
func remote_kill_detected(_victim: String, killer: String) -> void:
	increase_scoreboard_for(killer)


func _on_multiplayer_spawner_despawned(node: Node) -> void:
	node.disconnect("remotely_killed", _on_remote_kill)
  

func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node is Player:
		node.connect("remotely_killed", _on_remote_kill)


func increase_scoreboard_for(killer: String) -> void:
	if not scoreboard.has(killer):
		scoreboard[killer] = 0
	scoreboard[killer] += 1
	scoreboard_field.text = ""
	for key in scoreboard.keys():
		scoreboard_field.text += str(scoreboard[key]) + " / " + key
		scoreboard_field.text += "\n"
