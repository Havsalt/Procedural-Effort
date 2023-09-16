class_name SwatPistol
extends Firearm


@onready var shield: Armour = get_node_or_null("ShieldAttatchment/SwatShield")


func _ready() -> void:
	super._ready()
	if shield:
		hold_point_b = shield.hold_point_b


func _process(delta: float) -> void: # TODO: add remote toggle
	super._process(delta)
	if not active: return
	if not shield: return
	if shield.is_broken: return
	if shield.animation_player.is_playing(): return
	if not is_multiplayer_authority(): return
	if not Input.is_action_pressed("ctrl"): return
	# toggle shield
	if shield.is_visible_in_tree():
		shield.unequip()
	else:
		shield.equip()


func equip() -> void:
	super.equip()
	if shield and not shield.is_broken:
		shield.equip()


func unequip() -> void:
	super.unequip()
	if shield and not shield.is_broken:
		shield.unequip()

func on_respawn() -> void:
	if shield: # send downwards
		shield.on_respawn()
