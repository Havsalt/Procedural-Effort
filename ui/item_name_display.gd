extends Label


@export var item_slot: ItemSlot
@export var prefix: String = ""
@export var suffix: String = ""


func _ready() -> void:
	if item_slot:
		item_slot.connect("item_changed", _on_item_slot_item_changed)
	text = prefix + item_slot.item_name + suffix


func _on_item_slot_item_changed() -> void:
	text = prefix + item_slot.item_name + suffix
