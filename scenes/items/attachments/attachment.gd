class_name Attachment
extends Item


@export var override: Dictionary = {}


func _ready() -> void:
	equip() # TEST


func equip() -> void:
	super.equip()
	print("Attatchment owner is ", owner)
	for property in override.keys():
		print("Property: ", property)
		var value = override[property]
		owner.set(property, value)
		print(owner.get(property))
		prints("Setting:", property, "-->", value)
		print(owner.get(property))


func unequip() -> void:
	super.unequip()
	print("[Skip] Attathment onwer is ", owner)
