class_name Bow
extends Firearm


@export var drag_interval := 0.1
@export var velocity_bonus := 800
@export var bow_pushback_min: float = 1
@export var bow_pushback_max: float = 2
@export var bow_sway: float = 1
@export var bow_position_recovery := Vector2(0.15, 0.15)
@export var bow_motion_recovery := Vector2(0.10, 0.10)
@export var string_recovery: float = 0.70
@export var hand_recovery: float = 0.15
@export var hand_snap_margin: float = 0.5

@onready var string: Line2D = $String
@onready var holding_point: Marker2D = $HoldingPoint
@onready var drag_min: Marker2D = $DragMin
@onready var drag_max: Marker2D = $DragMax
@onready var timer_drag_interval: Timer = $TimerDragInterval
@onready var shadow: PointLight2D = $FloatPoint/MainSprite/Shadow
@onready var rest_position = position

var local_projectile = preload("res://scenes/projectiles/arrow.tscn")
var charging := false
var bow_motion := Vector2()


func _ready() -> void:
	shadow.set_as_top_level(true)
	shadow.global_scale = sprite.global_scale
	shadow.global_position = sprite.global_position + Vector2(16, 16) # NOTE: copy from arrow `shadow_offset`
	shadow.global_rotation = sprite.global_rotation
	if not active:
		hide()
	timer_cooldown.wait_time = 1.0 / firerate
	timer_drag_interval.wait_time = drag_interval
	float_point.visible = false


func _process(_delta: float) -> void:
	shadow.global_position = sprite.global_position + Vector2(16, 16) # NOTE: copy from arrow `shadow_offset`
	shadow.global_rotation = sprite.global_rotation
	
	if active and not animation_player.is_playing() or animation_player.assigned_animation == "reload":
		# override position
		hold_point_b.global_position = holding_point.global_position
	
	if active and not (animation_player.is_playing() and animation_player.current_animation == "reload"):
		if not is_visible_in_tree():
			return
		
	
		if not animation_player.is_playing():
			if Input.is_action_pressed("shoot") and not charging and can_shoot and not animation_player.is_playing():
				float_point.visible = true
				rpc("remote_set_arrow_visibility", true)
				charging = true
				timer_drag_interval.start()
			elif Input.is_action_just_released("shoot") and charging and can_shoot:
				charging = false
				if float_point.position.x <= drag_min.position.x: # has enough drag power
					var dist_from_max = float_point.global_position.distance_to(drag_max.global_position)
					var dist_from_min_to_max = drag_min.global_position.distance_to(drag_max.global_position)
					var bonus_percent = (dist_from_min_to_max - dist_from_max) / dist_from_min_to_max
					float_point.visible = false
					rpc("remote_set_arrow_visibility", false)
					# handle arrow spawn
					can_shoot = false
					var instance: Projectile = local_projectile.instantiate()
					owner.camera.shake(shake_energy * bonus_percent) # apply some camera shake
					instance.add_collision_exception_with(owner)
					instance.damage = damage
					instance.master_nickname = Globals.nickname
					owner.add_child(instance, true)
					instance.global_position = float_point.global_position
					var spread = randfloat(deg_to_rad(spread_angle_min), deg_to_rad(spread_angle_max))
					instance.global_rotation = float_point.global_rotation + spread
					instance.velocity = instance.global_position.direction_to(instance.forward.global_position) * (instance.speed + velocity_bonus * bonus_percent)
					instance.update_shadow()
					rpc("remote_spawn_projectile", instance.global_position, instance.global_rotation, instance.velocity, Globals.nickname)
					timer_cooldown.start()
					sound_shoot.play()
					# reset arrow recoil and rotation
					float_point.rotation = 0
					motion = Vector2.ZERO
					rotational_motion = 0
					# bow is single fire
					reload()
			elif not charging: # lerp back when fired
				float_point.position = float_point.position.lerp(Vector2.ZERO, string_recovery)
	
	# rest motion and position
	float_point.position.x = lerp(float_point.position.x, 0.0, recoil_recovery.x)
	float_point.position.y = lerp(float_point.position.y, 0.0, recoil_recovery.y)
	float_point.position += motion
	float_point.rotation = lerp_angle(float_point.rotation, 0.0, rot_recoil_recovery)
	float_point.rotation += rotational_motion
	motion.x = lerp(motion.x, 0.0, recoil_motion_recovery.x)
	motion.y = lerp(motion.y, 0.0, recoil_motion_recovery.y)
	rotational_motion = lerp(rotational_motion, 0.0, rot_recoil_motion_recovery)
	# handle bow position change
	if active and (not animation_player.is_playing() or animation_player.assigned_animation == "reload") and is_visible_in_tree():
		# override position
		hold_point_b.global_position = holding_point.global_position
	position.x = lerp(position.x, rest_position.x, bow_position_recovery.x)
	position.y = lerp(position.y, rest_position.y, bow_position_recovery.y)
	position += bow_motion
	bow_motion.x = lerp(bow_motion.x, 0.0, bow_motion_recovery.x)
	bow_motion.y = lerp(bow_motion.y, 0.0, bow_motion_recovery.y)
	if charging:
		bow_motion.x -= randfloat(bow_pushback_min, bow_pushback_max)
		bow_motion.y += randfloat(-bow_sway, bow_sway)
	# handle string points
	string.points[1] = Vector2(float_point.position)


func _on_timer_drag_interval_timeout() -> void:
	if charging:
		apply_recoil()
		timer_drag_interval.start()


@rpc("reliable", "call_remote", "any_peer")
func remote_set_arrow_visibility(value: bool) -> void:
	float_point.visible = value
