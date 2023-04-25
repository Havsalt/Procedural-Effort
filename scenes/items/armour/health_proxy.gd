class_name HealthProxy
extends Node2D


@export var target: Node2D

@onready var hp: int = target.hp :
	set(value):
		target.hp = value
	get:
		return target.hp
