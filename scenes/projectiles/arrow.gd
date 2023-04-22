class_name Arrow
extends Projectile


func destroy(collision: KinematicCollision2D) -> void:
	super.destroy(collision)
	if collision.get_collider() is Player:
		queue_free()
	# additional lifetime will be on
#	set_as_top_level(false)
#	reparent(collision.get_collider(), false)
#	global_position = collision.get_position()
#	rotation = collision.get_collider_velocity().angle()
