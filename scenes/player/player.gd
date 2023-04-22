class_name Player
extends CharacterBody2D


signal remotely_killed(who: String, by: String)
signal request_respawn


const ACCELERATION := 1000.0
const DEACCELERATION := 2100.0
const DIRECTION_CHANGE := 0.10
const MAX_SPEED := 600.0
const TURNING_RATE := 0.25
const CONTAINER_TURNING_RATE := 0.15
const ARM_R_REST_POSITION = Vector2(128, 32)
const ARM_L_REST_POSITION = Vector2(128, -32)
const INACTIVE_ARM_REST_RATE := 0.10
const COLORS = [
	Color.LIGHT_SKY_BLUE,
	Color("purple"),
	Color("yellow"),
	Color("red"),
	Color("green")
]

@export var max_hp: int = 100
@export var hp: float = max_hp :
	set (value):
		var prev_hp = hp
		hp = value
		hp_label.text = str(value) + "HP"
		if synchronizer.is_multiplayer_authority():
			if value < prev_hp: # if changed for the worse
				var energy = damage_shake_function(max(prev_hp - value, 0))
				camera.shake(energy)
		if value <= 0: # TODO: broadcast real hp value if is_multiplayer_authority()
			hp = max_hp
			hp_label.text = str(max_hp) + "HP"
			if not synchronizer.is_multiplayer_authority():
				return # this client determines whether it was killed (priority)
			if last_projectile_hit_master_nickname:
				emit_signal("remotely_killed", Globals.nickname, last_projectile_hit_master_nickname)
			emit_signal("request_respawn", self)
@export var proxy_velocity := Vector2() :
	set (value):
		if not synchronizer.is_multiplayer_authority():
			velocity = proxy_velocity # override
		else:
			proxy_velocity = value # broadcast
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var spawn_transition: CanvasLayer = $AnimationPlayer/SpawnTransition
@onready var camera: CameraShake2D = $Camera2D
@onready var items_pivot: Node2D = $ItemsPivot
@onready var items_container: Marker2D = items_pivot.get_node("ItemsContainer")
@onready var arm_l: Arm = $ArmL
@onready var arm_l_a = $ArmLShapeA
@onready var arm_l_b = $ArmLShapeB
@onready var arm_l_c = $ArmLShapeC
@onready var arm_r: Arm = $ArmR
@onready var arm_r_a = $ArmRShapeA
@onready var arm_r_b = $ArmRShapeB
@onready var arm_r_c = $ArmRShapeC
@onready var hp_pivot = $ItemsPivot/HPPivot
@onready var hp_anchor = $ItemsPivot/HPPivot/HPAnchor
@onready var hp_label = get_node("ItemsPivot/HPPivot/HPAnchor/Label")
@onready var items: Array[Node] = items_container.get_children()
@onready var held_item: Item = items_container.get_child(0) # current

var item_index: int = 0
var reverse_next_item_switch := false
var nickname: String
var last_projectile_hit_master_nickname: String


func _enter_tree() -> void: # temp fixes its state as inactive
	get_node("MultiplayerSynchronizer").set_multiplayer_authority(0)


func _ready() -> void:
	global_position = (
		Vector2(
			550,
			300
		) +
		Vector2(
			randint(-32, 32),
			randint(-32, 32)
		) * 8
	)
	# handle sync config
	synchronizer.set_multiplayer_authority(name.to_int(), true)
	if synchronizer.is_multiplayer_authority():
		camera.make_current()
	else:
		spawn_transition.hide()
	# handle hp label
	hp_label.text = str(hp) + "HP"
	hp_anchor.set_as_top_level(true)
	hp_anchor.global_rotation = 0.0
	hp_anchor.global_position = hp_pivot.global_position
	# handle items
	for item in items:
		item.connect("equipped", _on_item_equipped)
		item.connect("unequipped", _on_item_unequipped)
	items_pivot.set_as_top_level(true)
	items_pivot.global_position = global_position
	held_item.active = true
	held_item.visible = true # just in case
	# randomize arm colors
	randomize_arm_colors()
	# connect signal after owner is ready
	if synchronizer.is_multiplayer_authority():
		connect("request_respawn", get_parent().spawnpoint_manager.on_respawn_requested)


func _physics_process(delta: float) -> void:
	if animation_player.is_playing() and animation_player.assigned_animation == "respawn":
		return # playing respawn sequence
	
	if synchronizer.is_multiplayer_authority():
		var direction = Input.get_vector(
			"move_left", "move_right", "move_up", "move_down")
		if direction:
			velocity = (
				velocity.normalized().lerp(direction.normalized(), DIRECTION_CHANGE)
				* velocity.length() + direction * ACCELERATION * delta)
			if velocity.length() > MAX_SPEED:
				velocity = velocity.normalized() * MAX_SPEED
		else:
			velocity = velocity.move_toward(Vector2.ZERO, DEACCELERATION * delta)
		# handle player rotation and adding motion
		items_pivot.global_rotation = lerp_angle(items_container.global_rotation, (get_global_mouse_position() - global_position).angle(), CONTAINER_TURNING_RATE)
		global_rotation = lerp_angle(global_rotation, (get_global_mouse_position() - global_position).angle(), TURNING_RATE)
		move_and_slide()
	
	# handle right arm
	if held_item.use_hold_point_a:
		arm_r.target = held_item.hold_point_a.global_position
	else:
		if synchronizer.is_multiplayer_authority():
			arm_r.target = arm_r.hand.global_position.lerp(items_pivot.global_position + ARM_R_REST_POSITION.rotated(rotation), INACTIVE_ARM_REST_RATE)
		else:
			arm_r.target = items_pivot.global_position + ARM_R_REST_POSITION.rotated(rotation)
	# handle left arm
	if held_item.use_hold_point_b:
		arm_l.target = held_item.hold_point_b.global_position
	else:
		if synchronizer.is_multiplayer_authority():
			arm_l.target = arm_l.hand.global_position.lerp(items_pivot.global_position + ARM_L_REST_POSITION.rotated(rotation), INACTIVE_ARM_REST_RATE)
		else:
			arm_l.target = items_pivot.global_position + ARM_L_REST_POSITION.rotated(rotation)
	# WARNING: `item` may require `hold_point_a` and `hold_point_b`


func _process(_delta: float) -> void:
	# handle hp label
	hp_anchor.global_position = hp_pivot.global_position
	items_pivot.global_position = global_position
	# update arm shape segments
	arm_l_a.global_position = arm_l.upperarm.global_position
	arm_l_b.global_position = arm_l.forearm.global_position
	arm_l_c.global_position = arm_l.hand.global_position
	arm_l_a.global_rotation = arm_l.upperarm.global_rotation
	arm_l_b.global_rotation = arm_l.forearm.global_rotation
	arm_l_c.global_rotation = arm_l.hand.global_rotation
	arm_r_a.global_position = arm_r.upperarm.global_position
	arm_r_b.global_position = arm_r.forearm.global_position
	arm_r_c.global_position = arm_r.hand.global_position
	arm_r_a.global_rotation = arm_r.upperarm.global_rotation
	arm_r_b.global_rotation = arm_r.forearm.global_rotation
	arm_r_c.global_rotation = arm_r.hand.global_rotation


func _on_item_equipped(_item: Item) -> void:
	return


func _on_item_unequipped(_item: Item) -> void:
	if true: # DISABLED
		return
	if reverse_next_item_switch:
		item_index -= 1
		if item_index < 0:
			item_index = len(items) -1
	else:
		item_index += 1
		if item_index >= len(items):
			item_index = 0
	held_item.active = false
	held_item.hide()
	# assign the new item
	held_item = items[item_index]
	held_item.active = true
	held_item.equip()


func respawn(where: Spawnpoint) -> void:
	held_item.unequip()
	animation_player.play("respawn")
	global_position = where.animated_position.global_position
	camera.set_shake(0)
#	global_position = (
#		Vector2(
#			550,
#			300
#		) +
#		Vector2(
#			randint(-32, 32),
#			randint(-32, 32)
#		) * 8
#	)


func damage_shake_function(x: float) -> float: # f(x) -> ...
	if x == 0:
		return 0 # ZeroDivisonError
	x += 1 # offset
	return ((-0.005 * x*x) + (5 * log(x)) + (0.05 * x)) / 50.0


func randint(a: int, b: int) -> int:
	return randi() % (b - a +1) + a


func randomize_arm_colors() -> void: # DISABLED
	if true:
		return
	var color = COLORS[randint(0, COLORS.size() -1)]
	for arm in [arm_l, arm_r]:
		arm.upperarm.material = arm.upperarm.material.duplicate()
		arm.upperarm.material.set("shader_param/color", color)
		arm.forearm.material = arm.forearm.material.duplicate()
		arm.forearm.material.set("shader_param/color", color)
