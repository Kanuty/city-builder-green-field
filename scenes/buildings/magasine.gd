extends Node3D

@export var building_name: String = "Magasine"
@export var grid_size: Vector2i = Vector2i(2, 2)
@export var max_capacity: int = 64

var stored_items: Dictionary = {} # goods_type -> amount
var total_stored: int = 0
var reserved_space: int = 0

@onready var animation_player: AnimatedSprite3D = $AnimatedSprite3D

func _ready():
	Global.register_magazine(self)
	if animation_player:
		animation_player.play("idle")

func _exit_tree():
	Global.unregister_magazine(self)

func get_available_space() -> int:
	return max_capacity - total_stored - reserved_space

func reserve(amount: int) -> bool:
	if get_available_space() >= amount:
		reserved_space += amount
		return true
	return false

func cancel_reservation(amount: int):
	reserved_space = max(0, reserved_space - amount)

func receive_delivery(amount: int, goods_type: String):
	reserved_space = max(0, reserved_space - amount)

	if stored_items.has(goods_type):
		stored_items[goods_type] += amount
	else:
		stored_items[goods_type] = amount

	total_stored += amount
	print(building_name, " received ", amount, " ", goods_type, ". Total stored: ", total_stored)

	# Also update global inventory so UI shows it
	Global.add_goods(goods_type, amount)

func update_state():
	# Magasine currently has no state-based animations other than idle
	pass
