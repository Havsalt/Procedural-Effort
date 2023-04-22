class_name Projectile
extends CharacterBody2D


@export var damage := 1
@export var hp: int = 1 :
	set (value):
		hp = value
		if value <= 0:
			queue_free() # TODO: option to simulate collision
@export var speed := 750.0
@export var bounce_angle := 30
@export var length := 50
@export var additional_travel: float = 0
@export var shadow_offset := Vector2(16, 16)
@export var enable_additional_lifetime := false
@export var additional_lifetime: float = 5 # seconds # 0 < x < 10

@onready var timer_additional_lifetime = $TimerAdditionalLifetime
@onready var forward = $Forward
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sound_impact: AudioStreamPlayer2D = $SoundImpact
@onready var impact_particles: GPUParticles2D = get_node_or_null("ImpactParticles")
@onready var shadow: PointLight2D = get_node_or_null("Shadow")

var exceptions: Array = []
var has_collided := false
var master_nickname: String


func _ready() -> void:
	set_as_top_level(true)
	velocity = Vector2.RIGHT * speed
	update_shadow()


func _physics_process(delta: float) -> void:
	update_shadow()
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		var heading = velocity.bounce(collision.get_normal()).normalized()
		var a = heading.angle()
		var b = global_rotation
		if min(TAU - abs(a - b), abs(a - b)) > deg_to_rad(bounce_angle):
			_on_collision(collision)
			return
		velocity = heading * velocity.length() # switch direction
		global_rotation = heading.angle()
		global_position = collision.get_position()
		for exception in exceptions:
			if not is_instance_valid(exception):
				continue
			remove_collision_exception_with(exception)
		var exception = collision.get_collider()
		exceptions.append(exception)
		add_collision_exception_with(exception)


func _on_collision(collision: KinematicCollision2D) -> void:
	var collider = collision.get_collider()
	if collider is Projectile:
		self.hp -= 1
		# collider.hp -= 1 # effectively done at the end of this function
		add_collision_exception_with(collider)
	elif collider is Player:
		if master_nickname: # if spawned by oponent
			collider.last_projectile_hit_master_nickname = master_nickname
		destroy(collision) # self destroy protocol
	else:
		destroy(collision) # self destroy protocol
	# apply damage if possible
	if collider.get("hp") != null:
		collider.hp -= damage


func update_shadow() -> void:
	if shadow != null:
		shadow.global_position = sprite.global_position + shadow_offset
		shadow.global_rotation = sprite.global_rotation


func destroy(collision: KinematicCollision2D) -> void:
	if not sound_impact.stream and not impact_particles and not enable_additional_lifetime: # instantly queue for deletion
		queue_free()
	else:
		# get direction vector where it is heading
		var heading = velocity.normalized()
		global_position = collision.get_position() + (heading * (-length + additional_travel))
		global_rotation = heading.angle()
		
		if shadow and not enable_additional_lifetime:
			shadow.enabled = false
		
		if impact_particles:
			collision_shape.disabled = true
			velocity = Vector2.ZERO
			impact_particles.set_as_top_level(true)
			impact_particles.set_as_top_level(true)
			impact_particles.global_position = collision.get_position() + (heading * additional_travel)
			impact_particles.global_rotation = heading.angle()
			impact_particles.emitting = true
			has_collided = true
		
		if sound_impact:
			sound_impact.play()
		
		# whether to hide sprite or follow additional lifetime protocol
		if enable_additional_lifetime:
			timer_additional_lifetime.wait_time = additional_lifetime
			timer_additional_lifetime.start()
		else:
			sprite.visible = false
		
		# reset some states when stationary after collision
		collision_shape.disabled = true
		velocity = Vector2.ZERO


func _on_sound_impact_finished() -> void:
	if not impact_particles and not enable_additional_lifetime: # impact particles have priority
		queue_free()


func _on_lifetime_timeout() -> void:
	if timer_additional_lifetime.is_stopped(): # if not currently using additional lifetime
		queue_free()
	# else: additional lifetime will take care if started


func _on_additional_lifetime_timeout() -> void:
	queue_free()


func _process(_delta: float) -> void:
	if has_collided and not enable_additional_lifetime:
		if sound_impact:
			if sound_impact.is_playing():
				return
		if not impact_particles.emitting:
			queue_free()
