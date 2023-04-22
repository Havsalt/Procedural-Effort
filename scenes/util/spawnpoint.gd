class_name Spawnpoint
extends Marker2D


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


func is_active() -> bool:
	return animation_player.is_playing()


func _process(_delta: float) -> void:
	if animation_player.is_playing():
		handling.global_position = animated_position.global_position
		handling.global_rotation = animated_position.global_rotation
		handling.arm_l.target = animated_hand_l.global_position
		handling.arm_r.target = animated_hand_r.global_position


func _on_respawn_finished(_anim_name: StringName = "respawn") -> void:
	handling.held_item.equip()
	handling = null
