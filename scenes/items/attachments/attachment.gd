class_name Attachment
extends Item


@export var override: Dictionary = {}


func equip() -> void:
	super.equip()
	print("Attathment onwer is ", owner)
	for property in override.keys():
		var value = override[property]
		owner.set(property, value)


func unequip() -> void:
	super.unequip()
	print("[Skip] Attathment onwer is ", owner)
