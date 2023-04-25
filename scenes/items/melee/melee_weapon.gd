class_name MeleeWeapon
extends Weapon


enum MODE {
	SINGLE,
	CHARGE
}

@export var charge_multiplier := 1.5
@export var charge_time := 1.0
