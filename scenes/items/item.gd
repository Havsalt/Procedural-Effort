class_name Item
extends Node2D


signal unequipped(this)
signal equipped(this)

@export var item_name: String = ""
@export var item_icon: Texture2D
@export var active := false
@export var use_hold_point_a := true
@export var use_hold_point_b := false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var float_point: Marker2D = $FloatPoint
@onready var sprite: Sprite2D = $FloatPoint/MainSprite
@onready var hold_point_a: Marker2D = $FloatPoint/HoldPointA
@onready var hold_point_b: Marker2D = $FloatPoint/HoldPointB

var motion: Vector2 = Vector2()
var rotational_motion: float = 0


func randint(a: int, b: int) -> int:
	return randi() % (b - a +1) + a


func randfloat(a: float, b: float) -> float:
	return randf() * (b - a) + a


func equip() -> void:
	if not animation_player.has_animation("equip"):
		show() # default
		emit_signal("equipped", self)
		rpc("remote_set_visibility_state", true)
		return
	animation_player.play("equip")
	rpc("remote_play_animation", "equip")


func unequip() -> void:
	if not animation_player.has_animation("unequip"):
		hide() # default
		emit_signal("unequipped", self)
		rpc("remote_set_visibility_state", false)
		return
	animation_player.play("unequip")
	rpc("remote_play_animation", "unequip")


func on_respawn() -> void:
	return


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "equip":
		emit_signal("equipped", self)
	elif anim_name == "unequip":
		emit_signal("unequipped", self)


@rpc("reliable", "call_remote", "any_peer")
func remote_play_animation(anim_name: StringName) -> void:
	animation_player.assigned_animation = "dummy" # seems to work just fine
	animation_player.play(anim_name)


@rpc("reliable", "call_remote", "any_peer")
func remote_set_visibility_state(state: bool) -> void:
	visible = state
