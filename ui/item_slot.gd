class_name ItemSlot
extends Panel


signal item_changed

@export var item: PackedScene
@export var finite := true # holds a finite rescource (stacks to 1)
@export var subscribe := true
@export var publish := true
# if subscribe and publish -> swappable

@onready var texture_rect = $MarginContainer/TextureRect
@onready var drag_rect = $DragRect

var item_name: String = "" # last item name
var dragging := false


func _ready() -> void:
	# reset from editor debug
	drag_rect.texture = null
	texture_rect.texture = null
	# setup drag_rect's independency
	drag_rect.set_as_top_level(true)
	drag_rect.size = texture_rect.size
	drag_rect.hide()
	set_process(false)
	if item:
		set_texture_from_scene()
	drag_rect.texture = texture_rect.texture


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				set_process(true)
				texture_rect.hide()
				drag_rect.show()
				dragging = true
	
	elif event is InputEventScreenTouch:
		if event.index == 1: # one finger active
			if event.pressed:
				set_process(true)
				texture_rect.hide()
				drag_rect.show()
				dragging = true


func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and dragging:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed:
				set_process(false)
				texture_rect.show()
				drag_rect.hide()
				dragging = false
				# check whether to swap
				var point = get_global_mouse_position()
				if event is InputEventScreenTouch:
					point = event.position
				for container in get_containers():
					if container.get_global_rect().has_point(point): # `container` should be ItemSlot
						if subscribe and publish:
							var texture_copy = container.texture_rect.texture
							container.texture_rect.texture = texture_rect.texture
							container.drag_rect.texture = container.texture_rect.texture
							texture_rect.texture = texture_copy
							drag_rect.texture = texture_rect.texture
							var item_name_copy = container.item_name
							container.item_name = item_name
							item_name = item_name_copy
							var item_copy = container.item
							container.item = item
							item = item_copy
							container.emit_signal("item_changed")
							emit_signal("item_changed")
						# TODO: make cases for subscribe and publish


func _process(_delta: float) -> void:
	drag_rect.position = get_global_mouse_position()
	drag_rect.position -= texture_rect.size / 2
	drag_rect.size = texture_rect.size


func get_containers(slot_type: String = "slots") -> Array:
	return get_tree().get_nodes_in_group(slot_type)


func set_texture_from_scene() -> void:
	var instance: Item = item.instantiate()
	add_child(instance)
	texture_rect.texture = instance.item_icon
	item_name = instance.item_name
	instance.hide()
	instance.queue_free()
	emit_signal("item_changed")
