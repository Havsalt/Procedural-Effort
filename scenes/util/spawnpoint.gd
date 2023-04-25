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


func respawn_player(player: Player) -> void:
	handling = player
	player.respawn(self)
	animation_player.play("respawn_player") # transforms handled through animation proxies
	permission = PERMISSION.WHOLE_BODY
	handling.restriction = handling.RESTRICTION.NONE


func is_active() -> bool:
	return animation_player.is_playing()


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
	handling.held_item.equip() # TODO: make sure the player holds something


func _on_respawn_finished(_anim_name: StringName = "respawn") -> void:
	permission = PERMISSION.NONE
	handling.restriction = handling.RESTRICTION.NONE
	handling.held_item.equip()
	handling = null
