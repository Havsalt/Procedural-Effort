class_name Player
extends CharacterBody2D


signal remotely_killed(who: String, by: String)
signal request_respawn

enum RESTRICTION {
	NONE,
	SELF_TRANSFORM,
	WHOLE_BODY
}

const ACCELERATION := 1000.0
const DEACCELERATION := 2100.0
const DIRECTION_CHANGE := 0.10
const MAX_SPEED := 600.0
const TURNING_RATE := 0.25
const CONTAINER_TURNING_RATE := 0.15
const ARM_R_REST_POSITION = Vector2(128, 32)
const ARM_L_REST_POSITION = Vector2(128, -32)
const INACTIVE_ARM_REST_RATE := 0.10
const HP_LABEL_REST_RATE = 0.80
const COLORS = [
	Color.LIGHT_SKY_BLUE,
	Color("purple"),
	Color("yellow"),
	Color("red"),
	Color("green")
]

@export var max_hp: int = 100
@export var hp: float = max_hp :
	set(value):
		if not is_multiplayer_authority():
			return
		var prev_hp = hp
		hp = value
		hp_label.text = str(value) + "HP"
		if value < prev_hp: # took damage
			var energy = damage_shake_function(max(prev_hp - value, 0))
			camera.shake(energy)
		if value <= 0:
			hp = max_hp
			hp_label.text = str(max_hp) + "HP"
			if last_projectile_hit_master_nickname:
				emit_signal("remotely_killed", Globals.nickname, last_projectile_hit_master_nickname)
			emit_signal("request_respawn", self)
		rpc("remote_display_health", hp)
@export var proxy_velocity := Vector2() :
	set(value):
		if not is_multiplayer_authority():
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
@onready var arm_l_a: CollisionShape2D = $ArmLShapeA
@onready var arm_l_b: CollisionShape2D = $ArmLShapeB
@onready var arm_l_c: CollisionShape2D = $ArmLShapeC
@onready var arm_r: Arm = $ArmR
@onready var arm_r_a: CollisionShape2D = $ArmRShapeA
@onready var arm_r_b: CollisionShape2D = $ArmRShapeB
@onready var arm_r_c: CollisionShape2D = $ArmRShapeC
@onready var container_plate_r: Marker2D = $ContainerPlateR
@onready var hp_pivot = $ItemsPivot/HPPivot
@onready var hp_anchor = $ItemsPivot/HPPivot/HPAnchor
@onready var hp_label = get_node("ItemsPivot/HPPivot/HPAnchor/Label")
@onready var item_container_1: Node2D = $ItemsPivot/ItemsContainer/Item1
@onready var item_container_2: Node2D = $ItemsPivot/ItemsContainer/Item2
@onready var item_container_3: Node2D = $ItemsPivot/ItemsContainer/Item3
@onready var item_container_f: Node2D = $ItemsPivot/ItemsContainer/ItemF
@onready var item_container_e: Node2D = $ItemsPivot/ItemsContainer/ItemE
@onready var item_container_q: Node2D = $ItemsPivot/ItemsContainer/ItemQ
@onready var items: Array[Item] = get_items()
@onready var held_item: Item = null # current

var restriction: RESTRICTION = RESTRICTION.NONE
var item_index: int = 0
var nickname: String
var last_projectile_hit_master_nickname: String


func _enter_tree() -> void: # temp fixes its state as inactive
	set_multiplayer_authority(0)


func _ready() -> void:
	var plate_r: Armour = get_node_or_null("ContainerPlateR/ArmPlateR") # TODO: fixme
	plate_r.reparent(arm_r.forearm)
	# handle sync config
	set_multiplayer_authority(name.to_int(), true)
	if is_multiplayer_authority():
		camera.make_current()
	else:
		spawn_transition.hide()
	# handle hp label
	hp_label.text = str(hp) + "HP"
	hp_anchor.set_as_top_level(true)
	hp_anchor.global_rotation = 0.0
	hp_anchor.global_position = hp_pivot.global_position
	# connect signal after owner is ready
	if is_multiplayer_authority():
		connect("request_respawn", get_parent().spawnpoint_manager.on_respawn_requested)
		emit_signal("request_respawn", self) # initial spawn
		if Globals.item_1:
			var item_1: Item = Globals.item_1.instantiate()
			item_container_1.add_child(item_1, true)
		if Globals.item_2:
			var item_2: Item = Globals.item_2.instantiate()
			item_container_2.add_child(item_2, true)
		if Globals.item_3:
			var item_3: Item = Globals.item_3.instantiate()
			item_container_3.add_child(item_3, true)
		if Globals.item_f:
			var item_f: Item = Globals.item_f.instantiate()
			item_container_f.add_child(item_f, true)
		if Globals.item_e and false: # DISABLED
			var item_e: Item = Globals.item_e.instantiate()
			item_container_e.add_child(item_e, true)
		if Globals.item_q and false: # DISABLED
			var item_q: Item = Globals.item_q.instantiate()
			item_container_q.add_child(item_q, true)
		items = get_items() # refresh
		# handle items
		for item in items:
			item.connect("equipped", _on_item_equipped)
			item.connect("unequipped", _on_item_unequipped)
			item.owner = self
		# set first item active
		held_item = item_container_1.get_child(0) # TODO: make sure there is at least 1 item equipped
		held_item.active = true
		held_item.visible = true # just in case
		# update multiplayer auth
		set_multiplayer_authority(get_multiplayer_authority())
	else:
		set_process(false)
		set_physics_process(false)


func get_items() -> Array[Item]:
	var found: Array[Item] = []
	if container_plate_r.get_child_count() > 0:
		found.append(container_plate_r.get_child(0))
	if item_container_1.get_child_count() > 0:
		found.append(item_container_1.get_child(0))
	if item_container_2.get_child_count() > 0:
		found.append(item_container_2.get_child(0))
	if item_container_3.get_child_count() > 0:
		found.append(item_container_3.get_child(0))
	if item_container_f.get_child_count() > 0:
		found.append(item_container_f.get_child(0))
	if item_container_e.get_child_count() > 0:
		found.append(item_container_e.get_child(0))
	if item_container_q.get_child_count() > 0:
		found.append(item_container_q.get_child(0))
	return found


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():# and restriction >= RESTRICTION.SELF_TRANSFORM:
		var direction = Input.get_vector(
			"move_left", "move_right", "move_up", "move_down")
		if direction:
			velocity = (
				velocity.normalized().lerp(direction.normalized(), DIRECTION_CHANGE)
				* velocity.length() + direction * ACCELERATION * delta)
			if velocity.length() > MAX_SPEED:
				velocity = velocity.normalized() * MAX_SPEED
			camera.zoom = camera.zoom.lerp(Vector2(0.85, 0.85), 0.01)
		else:
			camera.zoom = camera.zoom.lerp(Vector2(0.95, 0.95), 0.05)
			velocity = velocity.move_toward(Vector2.ZERO, DEACCELERATION * delta)
		# handle player rotation and adding motion
		items_pivot.global_rotation = lerp_angle(items_container.global_rotation, (get_global_mouse_position() - global_position).angle(), CONTAINER_TURNING_RATE)
		global_rotation = lerp_angle(global_rotation, (get_global_mouse_position() - global_position).angle(), TURNING_RATE)
		move_and_slide()
	
#	if restriction == RESTRICTION.WHOLE_BODY:
#		return
	# handle right arm
	if held_item.use_hold_point_a:
		arm_r.target = held_item.hold_point_a.global_position
	else:
		if is_multiplayer_authority():
			arm_r.target = arm_r.hand.global_position.lerp(items_pivot.global_position + ARM_R_REST_POSITION.rotated(rotation), INACTIVE_ARM_REST_RATE)
		else:
			arm_r.target = items_pivot.global_position + ARM_R_REST_POSITION.rotated(rotation)
	# handle left arm
	if held_item.use_hold_point_b:
		arm_l.target = held_item.hold_point_b.global_position
	else:
		if is_multiplayer_authority():
			arm_l.target = arm_l.hand.global_position.lerp(items_pivot.global_position + ARM_L_REST_POSITION.rotated(rotation), INACTIVE_ARM_REST_RATE)
		else:
			arm_l.target = items_pivot.global_position + ARM_L_REST_POSITION.rotated(rotation)
	# WARNING: `item` may require `hold_point_a` and `hold_point_b`


func _process(_delta: float) -> void:
	# handle hp label
	hp_anchor.global_position = hp_anchor.global_position.lerp(hp_pivot.global_position, HP_LABEL_REST_RATE)
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
	
	if not is_multiplayer_authority() or held_item.animation_player.is_playing():
		return
	
	if Input.is_action_pressed("1") and item_container_1.get_child_count() and held_item != item_container_1.get_child(0):
		set_item_from_idx(0)
		
	elif Input.is_action_pressed("2") and item_container_2.get_child_count() and held_item != item_container_2.get_child(0):
		set_item_from_idx(1)
	
	elif Input.is_action_pressed("3") and item_container_3.get_child_count() and held_item != item_container_3.get_child(0):
		set_item_from_idx(2)
	
	elif Input.is_action_pressed("f") and item_container_f.get_child_count() and held_item != item_container_f.get_child(0):
		set_item_from_idx(3)
	# item `Q` and `E` are armour


func _on_item_equipped(_item: Item) -> void:
	return


func _on_item_unequipped(_item: Item) -> void:
	return


func respawn(where: Spawnpoint) -> void:
	if held_item:
		held_item.hide()
	animation_player.play("respawn")
	global_position = where.animated_position.global_position
	camera.set_shake(0)
	for item in items:
		item.on_respawn()


func damage_shake_function(x: float) -> float: # f(x) -> ...
	if x == 0:
		return 0 # ZeroDivisonError
	x += 1 # offset
	return ((-0.005 * x*x) + (5 * log(x)) + (0.05 * x)) / 50.0


func randint(a: int, b: int) -> int:
	return randi() % (b - a +1) + a


@rpc("reliable", "call_remote", "any_peer")
func remote_display_health(value: int) -> void:
	hp_label.text = str(value) + "HP"


func set_item_from_idx(idx: int) -> void:
	rpc("remote_set_item_from_idx", idx)
	held_item.active = false
	held_item.unequip()
	if held_item.animation_player.has_animation("unequip"):
		await held_item.animation_player.animation_finished
	if idx == 0:
		held_item = item_container_1.get_child(0)
	if idx == 1:
		held_item = item_container_2.get_child(0)
	if idx == 2:
		held_item = item_container_3.get_child(0)
	if idx == 3:
		held_item = item_container_f.get_child(0)
	held_item.equip()
	held_item.active = true


@rpc("reliable", "call_remote", "any_peer")
func remote_set_item_from_idx(idx: int) -> void:
	held_item.active = false
	held_item.unequip()
	if held_item.animation_player.has_animation("unequip"):
		await held_item.animation_player.animation_finished
	held_item = items[idx]
	held_item.equip()
	held_item.active = true
