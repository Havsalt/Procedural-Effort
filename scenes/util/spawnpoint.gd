class_name Spawnpoint
extends Marker2D


enum PERMISSION {
	NONE,
	SELF_TRANSFORM,
	WHOLE_BODY
}

@export var permission: PERMISSION = PERMISSION.NONE

@onready var animation_player = $AnimationPlayer
@onready var sound_breach = $SoundBreach
@onready var sound_reach = $SoundReach
@onready var animated_position = $AnimatedPosition
@onready var animated_hand_l = $AnimatedHandL
@onready var animated_hand_r = $AnimatedHandR

var handling: Player = null
var remote_handling := false


func respawn_player(player: Player) -> void:
	print("RESP: ", player)
	handling = player
	player.respawn(self)
	animation_player.play("respawn_player") # transforms handled through animation proxies
	permission = PERMISSION.WHOLE_BODY
	handling.restriction = handling.RESTRICTION.NONE
	rpc("remote_set_status", true)


func is_active() -> bool:
	return animation_player.is_playing() or remote_handling


func _process(_delta: float) -> void:
	if animation_player.is_playing() and permission != PERMISSION.NONE:
		handling.restriction = handling.RESTRICTION.SELF_TRANSFORM
		handling.global_position = animated_position.global_position
		handling.global_rotation = animated_position.global_rotation
		if permission == PERMISSION.WHOLE_BODY:
			handling.restriction = handling.RESTRICTION.WHOLE_BODY
			handling.arm_l.target = animated_hand_l.global_position
			handling.arm_r.target = animated_hand_r.global_position


func force_player_equip() -> void:
	if not handling.held_item: # may be remote dummy
		return
	handling.held_item.equip() # TODO: make sure the player holds something


func _on_respawn_finished(_anim_name: StringName = "respawn") -> void:
	permission = PERMISSION.NONE
	handling.restriction = handling.RESTRICTION.NONE
	if handling.held_item:
		handling.held_item.equip()
	handling = null
	rpc("remote_set_status", false)


@rpc("reliable", "call_remote", "any_peer")
func remote_set_status(status: bool) -> void:
	remote_handling = status
