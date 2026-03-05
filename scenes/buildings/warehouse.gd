extends Node3D

@export var building_name: String = "Warehouse"
@export var grid_size: Vector2i = Vector2i(2, 2)
@export var max_capacity: int = 64

var stored_items: Dictionary = {} # goods_type -> amount
var total_stored: int = 0
var reserved_space: int = 0

@onready var animation_player: AnimatedSprite3D = $AnimatedSprite3D

var item_sprites: Array = []
var visual_slots: Array = []
var next_slot_index: int = 0

var potato_texture = preload("res://img/goods/potato.png")
var carrots_texture = preload("res://img/goods/carrots_01.png")
var clay_texture = preload("res://img/clay/clay.png")
var pottery_texture = preload("res://img/clay/pottery.png")
var food_texture = preload("res://img/food/food.png")

func _ready():
	_register_in_global.call_deferred()
	if animation_player:
		animation_player.play("idle")
	_initialize_visual_slots()

func _initialize_visual_slots():
	# Generate exactly 64 positions, skipping a chunk in the top-left (e.g. X < 0, Z < 0)
	# For a 2x2 building, local coords range roughly from -1 to 1 in X and Z.
	# We use an 9x9 grid, which is 81 points. We remove a 4x4 block (16 points) from the top-left, leaving 65 points.
	# We take the first 64 of those.
	for i in range(9):
		for j in range(9):
			if i < 4 and j < 4:
				continue # Skip top-left corner
			if visual_slots.size() >= max_capacity:
				break
			var x = -0.8 + i * (1.6 / 8.0)
			var z = -0.8 + j * (1.6 / 8.0)
			visual_slots.append(Vector3(x, 0, z))

func _add_visual_item(goods_type: String):
	if next_slot_index >= visual_slots.size():
		return
	var pos = visual_slots[next_slot_index]
	next_slot_index += 1

	var sprite = Sprite3D.new()
	if goods_type == "Carrots":
		sprite.texture = carrots_texture
	elif goods_type == "Potato":
		sprite.texture = potato_texture
	elif goods_type == "Clay":
		sprite.texture = clay_texture
	elif goods_type == "Pottery":
		sprite.texture = pottery_texture
	elif goods_type == "Food":
		sprite.texture = food_texture
	else:
		sprite.texture = potato_texture # fallback

	# Adjust properties
	sprite.axis = Vector3.AXIS_Y
	sprite.pixel_size = 0.001 # scale them down properly
	sprite.render_priority = 1
	# Random Y rotation and Y offset
	sprite.rotation.y = (randi() % 4) * PI / 2.0
	sprite.position = pos + Vector3(0, 0.01 + randf_range(0.0, 0.01), 0)

	add_child(sprite)
	item_sprites.append(sprite)

func _register_in_global():
	Global.register_warehouse(self)

func _exit_tree():
	Global.unregister_warehouse(self)
	for goods_type in stored_items:
		Global.remove_goods(goods_type, stored_items[goods_type])

func get_available_space() -> int:
	return max_capacity - total_stored - reserved_space

func reserve(amount: int) -> bool:
	if get_available_space() >= amount:
		reserved_space += amount
		return true
	return false

func cancel_reservation(amount: int):
	reserved_space = max(0, reserved_space - amount)

func reserve_for_fetch(amount: int, goods_type: String) -> bool:
	if stored_items.has(goods_type) and stored_items[goods_type] >= amount:
		stored_items[goods_type] -= amount
		total_stored -= amount
		Global.remove_goods(goods_type, amount)
		# Temporarily removing sprites for simplicity when fetching
		var removed = 0
		var keep_sprites = []
		for sprite in item_sprites:
			# Not an exact goods_type match for removal, just removing N sprites
			if removed < amount:
				sprite.queue_free()
				removed += 1
			else:
				keep_sprites.append(sprite)
		item_sprites = keep_sprites
		next_slot_index -= removed
		return true
	return false

func remove_for_fetch(amount: int, goods_type: String):
	pass # Logic is handled in reserve_for_fetch to ensure items aren't taken by others

func receive_delivery(amount: int, goods_type: String):
	reserved_space = max(0, reserved_space - amount)

	if stored_items.has(goods_type):
		stored_items[goods_type] += amount
	else:
		stored_items[goods_type] = amount

	total_stored += amount
	print(building_name, " received ", amount, " ", goods_type, ". Total stored: ", total_stored)

	# Update visual representation
	for i in range(amount):
		if total_stored - amount + i < max_capacity:
			_add_visual_item(goods_type)

	# Also update global inventory so UI shows it
	Global.add_goods(goods_type, amount)

func update_state():
	# Warehouse currently has no state-based animations other than idle
	pass
