class_name Arrow
extends Projectile


func destroy(collision: KinematicCollision2D) -> void:
	super.destroy(collision)
	if collision.get_collider() is Player or collision.get_collider() is Armour:
		z_index -= 2 # so it shows behind arms
		queue_free()
	# additional lifetime will be on
#	set_as_top_level(false)
#	reparent(collision.get_collider(), false)
#	global_position = collision.get_position()
#	rotation = collision.get_collider_velocity().angle()
