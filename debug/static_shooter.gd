extends Node2D


@onready var smg: Firearm = $SMG
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer


func _ready() -> void:
	smg.label.hide()
	smg.set_process(false)


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("3"):
		smg.handle_projectile_spawn()


func _process(_delta: float) -> void:
	# rest motion and position
	smg.float_point.position.x = lerp(smg.float_point.position.x, 0.0, smg.recoil_recovery.x)
	smg.float_point.position.y = lerp(smg.float_point.position.y, 0.0, smg.recoil_recovery.y)
	smg.float_point.position += smg.motion
	smg.float_point.rotation = lerp_angle(smg.float_point.rotation, 0.0, smg.rot_recoil_recovery)
	smg.float_point.rotation += smg.rot_motion
	smg.motion.x = lerp(smg.motion.x, 0.0, smg.recoil_motion_recovery.x)
	smg.motion.y = lerp(smg.motion.y, 0.0, smg.recoil_motion_recovery.y)
	smg.rot_motion = lerp(smg.rot_motion, 0.0, smg.rot_recoil_motion_recovery)
