class_name ItemSlot
extends Panel


@export var item: PackedScene
@export var finite := true # holds a finite rescource (stacks to 1)
@export var subscribe := true
@export var publish := true
# if subscribe and publish -> swappable

@onready var texture_rect = $MarginContainer/TextureRect
@onready var drag_rect = $DragRect
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport

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
	set_texture_from_scene()
	await RenderingServer.frame_post_draw
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
					if container.get_global_rect().has_point(point):
						if subscribe and publish:
							var texture_copy = container.texture_rect.texture
							container.texture_rect.texture = texture_rect.texture
							container.drag_rect.texture = container.texture_rect.texture
							texture_rect.texture = texture_copy
							drag_rect.texture = texture_rect.texture


func _process(_delta: float) -> void:
	drag_rect.position = get_global_mouse_position()
	drag_rect.position -= texture_rect.size / 2
	drag_rect.size = texture_rect.size


func get_containers(slot_type: String = "slots") -> Array:
	return get_tree().get_nodes_in_group(slot_type)


func set_texture_from_scene() -> void:
	var instance = item.instantiate()
	sub_viewport.add_child(instance)
	instance.position = Vector2.ZERO + Vector2(64, 32) # try to center
	sub_viewport_container.show()
	await RenderingServer.frame_post_draw
	var result = sub_viewport.get_texture()
#	sub_viewport_container.hide() # TODO: hide sub viewport
	texture_rect.texture = result
