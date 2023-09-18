class_name Armour
extends Item


enum BREAK_MODE {
	FINITE,
	REGENERATIVE,
	FINITE_REGENERATIVE
}

enum REACTION_MODE {
	STATIC,
	RESPOND
}

enum RESPONSE_MODE {
	TAKE_DAMAGE,
	TAKE_DAMAGE_AND_STOP_REGENERATION
}

enum LABEL_BEHAVIOUR {
	STATIC,
	FLOATING
}

const HP_ANCHOR_FOLLOW = 0.03

@export var break_mode: BREAK_MODE = BREAK_MODE.FINITE
@export var reaction_mode: REACTION_MODE = REACTION_MODE.STATIC
@export var response_mode: RESPONSE_MODE = RESPONSE_MODE.TAKE_DAMAGE
@export var label_behaviour: LABEL_BEHAVIOUR = LABEL_BEHAVIOUR.STATIC
@export var max_hp: int = 50
@export var hp: int = 50 :
	set(value):
		if not is_inside_tree():
			return
		if not is_multiplayer_authority():
			return
		if value < hp: # took damage
			var diff = hp - value
			if reaction_mode == REACTION_MODE.RESPOND:
				motion.x -= randfloat(force_min.x, force_max.x) * (diff * force_responsiveness)
				motion.y += randfloat(force_min.y, force_max.y) * (diff * force_responsiveness)
				rotational_motion += randfloat(rot_force_min, rot_force_max)
			if response_mode == RESPONSE_MODE.TAKE_DAMAGE_AND_STOP_REGENERATION:
				timer_regeneration_delay.stop()
			if break_mode == BREAK_MODE.REGENERATIVE:
				timer_regeneration_delay.start()
		hp = max(value, 0) # finally set the property (take damage)
		label.text = str(hp) + "HP"
		if hp == 0:
			collision_shape.disabled = true
			if animation_player.has_animation("broke"):
				animation_player.play("broke")
			else:
				hide()
			if break_mode != BREAK_MODE.REGENERATIVE:
				is_broken = true
				rpc("remote_break")
@export var regeneration_duration: float = 2.5 # seconds
@export var regeneration_delay: float = 2.5 # seconds
@export var force_responsiveness: float = 0.50 # %
@export var force_min := Vector2(1, -2)
@export var force_max := Vector2(1, 2)
@export var recovery := Vector2(0.20, 0.20)
@export var motion_recovery := Vector2(0.15, 0.15)
@export var rot_force_min: float = -0.05
@export var rot_force_max: float = 0.05
@export var rot_recovery: float = 0.20
@export var rot_motion_recovery: float = 0.15

@onready var timer_regeneration_delay: Timer = $TimerRegenerationDelay
@onready var collision_shape: CollisionShape2D = $FloatPoint/Defence/CollisionShape2D # TODO: implement search
@onready var defence_sprite: Sprite2D = $FloatPoint/Defence/DefenceSprite
@onready var hp_pivot: Marker2D = $FloatPoint/Defence/HPPivot
@onready var hp_anchor: Marker2D = $FloatPoint/Defence/HPPivot/HPAnchor
@onready var label: Label = $FloatPoint/Defence/HPPivot/HPAnchor/Label
@onready var health_proxy: HealthProxy = $FloatPoint/Defence

var health_tween: Tween = null
var is_broken := false


func _ready() -> void:
	defence_sprite.show()
	if not active:
		hide()
	timer_regeneration_delay.wait_time = regeneration_delay
	if label_behaviour == LABEL_BEHAVIOUR.FLOATING:
		hp_anchor.set_as_top_level(true)
		hp_anchor.global_position = hp_anchor.global_position.lerp(hp_pivot.global_position, HP_ANCHOR_FOLLOW)
	label.text = str(hp) + "HP"


func set_collision_state(state: bool) -> void:
	collision_shape.disabled = not state
	rpc("remote_set_collision_state", state)


func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		label.visible = false
		return
	
	hp_anchor.global_position = hp_pivot.global_position
	# rest motion and position
	float_point.position.x = lerp(float_point.position.x, 0.0, recovery.x)
	float_point.position.y = lerp(float_point.position.y, 0.0, recovery.y)
	float_point.position += motion
	float_point.rotation = lerp_angle(float_point.rotation, 0.0, rot_recovery)
	float_point.rotation += rotational_motion
	motion.x = lerp(motion.x, 0.0, motion_recovery.x)
	motion.y = lerp(motion.y, 0.0, motion_recovery.y)
	rotational_motion = lerp(rotational_motion, 0.0, rot_motion_recovery)


func on_respawn() -> void:
	equip()
	hp = max_hp
	is_broken = false
	defence_sprite.show()


func _on_regeneration_delay_timeout() -> void:
	var percent = 1.00
	if hp != 0:
		percent = max_hp / float(hp)
	hp += 1 # assure some hp was regained
	collision_shape.disabled = false
	show()
	if hp == max_hp: return # skip tweening
	if health_tween:
		health_tween.kill()
	health_tween = get_tree().create_tween()
	health_tween.tween_property(self, "hp", max_hp, percent * regeneration_duration)


@rpc("reliable", "call_remote", "any_peer")
func remote_set_collision_state(state: bool) -> void: # true -> on | false -> off
	collision_shape.disabled = not state


@rpc("reliable", "call_remote", "any_peer")
func remote_break() -> void:
	# TODO: implement regen broadcast
	label.text = "0HP"
	collision_shape.disabled = true
	if animation_player.has_animation("broke"):
		animation_player.play("broke")
	else:
		hide()
	defence_sprite.hide()
	if break_mode != BREAK_MODE.REGENERATIVE:
		is_broken = true
