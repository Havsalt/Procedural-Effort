class_name Firearm
extends Item


signal unequipped(this)
signal equipped(this)


enum MODE {
	SEMI,
	BURST,
	AUTO,
	BURST_AUTO
}

@export var mode: MODE = MODE.SEMI
@export var use_projectile := true
@export var projectile: PackedScene = preload("res://scenes/projectiles/projectile.tscn")
@export var auto_reload := true
@export var max_ammo := 8
@export var ammo := 8
@export var firerate: float = 15
@export var burst_rate: float = 20
@export var burst_count: int = 3
@export var pellet_count: int = 1
@export var recoil_min := Vector2(5, -2)
@export var recoil_max := Vector2(10, 2)
@export var recoil_recovery := Vector2(0.20, 0.20)
@export var recoil_motion_recovery := Vector2(0.15, 0.15)
@export var rot_recoil_min: float = -0.05
@export var rot_recoil_max: float = 0.05
@export var rot_recoil_recovery: float = 0.20
@export var rot_recoil_motion_recovery: float = 0.15
@export var spread_angle_min: float = -5 # degrees
@export var spread_angle_max: float = 5 # degrees
@export var shake_energy := 0.1

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer_cooldown: Timer = $TimerCooldown
@onready var timer_burst_cooldown: Timer = $TimerBurstCooldown
@onready var sound_shoot: AudioStreamPlayer2D = $FloatPoint/Muzzle/SoundShoot
@onready var float_point: Marker2D = $FloatPoint
@onready var muzzle: Marker2D = $FloatPoint/Muzzle
@onready var hold_point_a: Marker2D = $FloatPoint/HoldPointA
@onready var hold_point_b: Marker2D = $FloatPoint/HoldPointB
@onready var magazine: Marker2D = $FloatPoint/Magazine
@onready var label: Label = $FloatPoint/Label

var can_shoot := true
var is_bursting := false
var current_burst := 0
var motion := Vector2()
var rot_motion: float = 0


func _ready() -> void:
	if not owner is Player:
		set_process(false)
		return # deactivation if not used by a player
	
	if not active:
		hide()
	timer_cooldown.wait_time = 1.0 / firerate
	timer_burst_cooldown.wait_time = 1.0 / burst_rate
	label.text = str(ammo) + "/" + str(max_ammo)


func _process(_delta: float) -> void:
	if not owner.synchronizer.is_multiplayer_authority():
		label.visible = false
		return
	
	if active and not (animation_player.is_playing() and animation_player.current_animation == "reload"):
		if Input.is_action_just_pressed("1") and not is_visible_in_tree() and not animation_player.is_playing():
			owner.reverse_next_item_switch = false
			equip()
		# DISABLED
#		elif Input.is_action_just_pressed("1") and is_visible_in_tree() and not animation_player.is_playing():
#			owner.reverse_next_item_switch = true
#			unequip()
		elif Input.is_action_just_pressed("2") and is_visible_in_tree() and not animation_player.is_playing():
			owner.reverse_next_item_switch = false
			unequip()
		
		if not is_visible_in_tree():
			return
		
		if not animation_player.is_playing():
			if Input.is_action_just_pressed("reload") or ammo == 0:
				reload()
			elif ammo != 0 and can_shoot:
				match mode:
					MODE.SEMI:
						if Input.is_action_just_pressed("shoot"):
							handle_projectile_spawn()
							timer_cooldown.start()
					MODE.BURST:
						if Input.is_action_just_pressed("shoot") and not is_bursting:
							is_bursting = true
							handle_projectile_spawn()
							current_burst += 1
							if current_burst >= burst_count:
								is_bursting = false
								current_burst = 0
								timer_cooldown.start()
							else:
								timer_burst_cooldown.start()
					MODE.AUTO:
						if Input.is_action_pressed("shoot"):
							handle_projectile_spawn()
							timer_cooldown.start()
					MODE.BURST_AUTO:
						if Input.is_action_pressed("shoot") and not is_bursting:
							is_bursting = true
							handle_projectile_spawn()
							current_burst += 1
							if current_burst >= burst_count:
								is_bursting = false
								current_burst = 0
								timer_cooldown.start()
							else:
								timer_burst_cooldown.start()
	# rest motion and position
	float_point.position.x = lerp(float_point.position.x, 0.0, recoil_recovery.x)
	float_point.position.y = lerp(float_point.position.y, 0.0, recoil_recovery.y)
	float_point.position += motion
	float_point.rotation = lerp_angle(float_point.rotation, 0.0, rot_recoil_recovery)
	float_point.rotation += rot_motion
	motion.x = lerp(motion.x, 0.0, recoil_motion_recovery.x)
	motion.y = lerp(motion.y, 0.0, recoil_motion_recovery.y)
	rot_motion = lerp(rot_motion, 0.0, rot_recoil_motion_recovery)


func apply_recoil() -> void:
	motion.x -= randfloat(recoil_min.x, recoil_max.x)
	motion.y += randfloat(recoil_min.y, recoil_max.y)
	rot_motion += randfloat(rot_recoil_min, rot_recoil_max)


func handle_projectile_spawn() -> void:
	# handle projectile spawn and ammo cost
	ammo -= 1
	label.text = str(ammo) + "/" + str(max_ammo)
	can_shoot = false
	var instances = []
	for _pellet in pellet_count:
		if not use_projectile: # DEV_ move this into Melee class
			continue
		var instance: Projectile = projectile.instantiate()
		instance.add_collision_exception_with(owner)
		instances.append(instance)
		instance.master_nickname = Globals.nickname
		owner.add_child(instance, true)
		instance.global_position = muzzle.global_position
		var muzzle_direction = (muzzle.global_position - float_point.global_position).normalized()
		var spread = randfloat(deg_to_rad(spread_angle_min), deg_to_rad(spread_angle_max))
		instance.global_rotation = muzzle_direction.angle() + spread
		instance.velocity = instance.global_position.direction_to(instance.forward.global_position) * instance.speed
		instance.update_shadow()
		rpc("remote_spawn_projectile", instance.global_position, instance.global_rotation, instance.velocity, Globals.nickname)
	for instance1 in instances: # make pellets not collide with eachother
		for instance2 in instances:
			if instance1 == instance2: continue
			instance1.add_collision_exception_with(instance2)
	instances.clear()
	# play sound
	sound_shoot.play()
	# apply recoil
	apply_recoil()
	owner.camera.shake(shake_energy)


func reload() -> void:
	if not animation_player.has_animation("reload"):
		ammo = max_ammo
		label.text = str(ammo) + "/" + str(max_ammo)
		return
	animation_player.assigned_animation = "dummy" # seems to work just fine
	animation_player.play("reload")
	rpc("remote_play_animation", "reload")


func equip() -> void:
	if not animation_player.has_animation("equip"):
		show() # default
		emit_signal("equipped", self)
		return
	animation_player.play("equip")
	rpc("remote_play_animation", "equip")


func unequip() -> void:
	if not animation_player.has_animation("unequip"):
		hide() # default
		emit_signal("unequipped", self)
		return
	animation_player.play("unequip")
	rpc("remote_play_animation", "unequip")


func randint(a: int, b: int) -> int:
	return randi() % (b - a +1) + a


func randfloat(a: float, b: float) -> float:
	return randf() * (b - a) + a


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "reload":
		ammo = max_ammo
		label.text = str(ammo) + "/" + str(max_ammo)
	elif anim_name == "equip":
		emit_signal("equipped", self)
	elif anim_name == "unequip":
		emit_signal("unequipped", self)


func _on_cooldown_timeout() -> void:
	can_shoot = true


func _on_burst_cooldown_timeout() -> void:
	if ammo > 0:
		handle_projectile_spawn()
		current_burst += 1
		if current_burst >= burst_count:
			is_bursting = false
			current_burst = 0
			timer_cooldown.start()
		else:
			timer_burst_cooldown.start()
	else:
		is_bursting = false
		current_burst = 0
		timer_cooldown.start()


@rpc("reliable", "call_remote", "any_peer")
func remote_spawn_projectile(pos: Vector2, rot: float, vel: Vector2, master_nickname: String) -> void:
	var instance: Projectile = projectile.instantiate()
	instance.add_collision_exception_with(owner)
	instance.master_nickname = master_nickname
	owner.add_child(instance)
	instance.global_position = pos
	instance.global_rotation = rot
	instance.velocity = vel
	instance.update_shadow()
	sound_shoot.play()


@rpc("reliable", "call_remote", "any_peer")
func remote_play_animation(anim_name: StringName) -> void:
	if anim_name == "reload":
		animation_player.assigned_animation = "dummy" # seems to work just fine
	animation_player.play(anim_name)
