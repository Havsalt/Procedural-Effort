class_name Arm
extends Marker2D


@export var flipped: bool = false

@onready var upperarm: Sprite2D = $Upperarm
@onready var forearm: Sprite2D = $Lbow/Forearm
@onready var hand: Sprite2D = $Lbow/Wrist/Hand
@onready var point_c: Node2D = $Lbow
@onready var point_b: Node2D = $Lbow/Wrist
@onready var b_side: float = point_c.position.x
@onready var a_side: float = point_b.position.x
@onready var total_length: float = a_side + b_side
@onready var target: Vector2 = point_b.global_position


func _process(_delta: float) -> void:
	target = global_position + (target - global_position).normalized() * min((target - global_position).length() - 1, total_length - 1)
	point_b.global_position = target
	
	var c_side = (point_b.global_position - global_position).length()
	var angle_a = law_of_cos(b_side, c_side, a_side)
	if is_nan(angle_a): # detect invalid angle to prevent arms from despawning
		return
	var angle_c = asin((c_side * sin(angle_a)) / a_side)
	var angle_b = PI - angle_a - angle_c
	
	if flipped:
		angle_a = -angle_a
		angle_b = -angle_b
		angle_c = -angle_c
	
	look_at(target)
	rotation -= angle_a
	point_c.look_at(target)
	point_b.rotation = angle_b


func law_of_cos(a: float, b: float, c: float) -> float: # -> angle B
	if 2 * a * b == 0:
		return 0.01
	return acos( (a*a + b*b - c*c) / (2 * a * b))
