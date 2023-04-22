extends Projectile


@export var explosion_damage := 20

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var trail: GPUParticles2D = $Trail
@onready var explosion: Area2D = $Explosion
@onready var sight_checker: RayCast2D = $Explosion/SightChecker
@onready var explosion_radius: CollisionShape2D = $Explosion/ExplosionRadius

var seen: Array = []


func _ready() -> void:
	super._ready()


func destroy(collision: KinematicCollision2D) -> void:
	super.destroy(collision)
	animated_sprite.hide()
	trail.emitting = false
	# enable explosion field
	explosion.monitoring = true
	explosion.monitorable = true
	explosion.set_as_top_level(true)
	explosion.global_position = collision.get_position()
	var _bodies = explosion.get_overlapping_bodies() # updates the area
	# AOE damage is calculated in `_on_explosion_body_entered`


func _on_explosion_body_entered(body: Node2D) -> void:
	if not body is Projectile or not body is Player and not body in seen:
		return
	sight_checker.target_position = body.global_position - explosion.global_position
	sight_checker.force_raycast_update()
	if sight_checker.is_colliding():
		if sight_checker.get_collider() == body: # if line of sight
			# Projectile and Player has `hp`
			body.hp -= explosion_damage
	seen.append(body)
	print(body)
