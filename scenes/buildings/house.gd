extends Node3D

@export var building_name: String = "House"
@export var grid_size: Vector2i = Vector2i(1, 1)
@export var unit_type: PackedScene

var max_food_capacity: int = 20
var max_pottery_capacity: int = 10

var stored_food: int = 0
var stored_pottery: int = 0

var house_level: int = 0

var current_population: int = 0
var reserved_population: int = 0

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var consume_timer: Timer = $ConsumeTimer
@onready var fetch_timer: Timer = $FetchTimer
@onready var timeout_timer: Timer = $TimeoutTimer

var active_fetches: int = 0

func _ready():
	# Update colors to default level
	update_visuals()

func receive_fetched_goods(amount: int, goods_type: String):
	active_fetches -= 1
	if goods_type == "Food":
		stored_food = min(max_food_capacity, stored_food + amount)
	elif goods_type == "Pottery":
		stored_pottery = min(max_pottery_capacity, stored_pottery + amount)
	update_level()

func try_fetch_goods(goods_type: String, needed_amount: int) -> int:
	if active_fetches >= 4:
		return 0

	var target_warehouse = null
	var min_dist = INF

	for warehouse in Global.warehouses:
		var available = warehouse.get_available_for_fetch(goods_type)
		if available > 0:
			var dist = global_position.distance_to(warehouse.global_position)
			if dist < min_dist:
				min_dist = dist
				target_warehouse = warehouse

	if target_warehouse:
		var available = target_warehouse.get_available_for_fetch(goods_type)
		var amount_to_fetch = min(needed_amount, available, 4)
		if amount_to_fetch > 0:
			if target_warehouse.reserve_for_fetch(amount_to_fetch, goods_type):
				if unit_type:
					var unit = unit_type.instantiate()
					get_parent().add_child(unit)
					unit.global_position = global_position
					unit.delivery_finished.connect(_on_unit_delivery_finished)
					unit.delivery_failed.connect(_on_unit_delivery_failed)
					unit.setup_fetch(self, target_warehouse, goods_type, amount_to_fetch, timeout_timer.wait_time)
					active_fetches += 1
					return amount_to_fetch
	return 0

func _on_unit_delivery_finished(amount_delivered: int):
	# Decrement fetch counter (goods handled in receive_fetched_goods)
	pass # It's actually handled in receive_fetched_goods now. active_fetches -= 1 is there.

func _on_unit_delivery_failed(reason: String = "Unknown reason"):
	active_fetches -= 1

func _on_fetch_timer_timeout():
	var food_threshold = int(max_food_capacity * 0.3)
	var pottery_threshold = int(max_pottery_capacity * 0.3)

	if stored_food < food_threshold:
		var needed = max_food_capacity - stored_food
		var fetched = 0
		if needed > 0:
			fetched = try_fetch_goods("Food", needed)
			needed -= fetched

	if stored_pottery < pottery_threshold:
		try_fetch_goods("Pottery", max_pottery_capacity - stored_pottery)

func _on_consume_timer_timeout():
	var food_consumed = house_level
	var pottery_consumed = 1 if house_level >= 2 else 0

	stored_food = max(0, stored_food - food_consumed)
	stored_pottery = max(0, stored_pottery - pottery_consumed)

	update_level()

func get_max_population(level: int) -> int:
	if level == 0:
		return 2
	elif level == 1:
		return 5
	elif level == 2:
		return 11
	elif level == 3:
		return 17
	elif level == 4:
		return 25
	return 0

func get_available_space() -> int:
	return get_max_population(house_level) - current_population - reserved_population

func reserve_pop():
	reserved_population += 1

func cancel_reserve_pop():
	reserved_population = max(0, reserved_population - 1)

func add_pop():
	reserved_population = max(0, reserved_population - 1)
	current_population += 1
	Global.add_population(1)

func _exit_tree():
	if current_population > 0:
		Global.remove_population(current_population)

func update_level():
	var old_level = house_level

	if stored_food == 0:
		house_level = 0
	elif stored_pottery > 0 and stored_food > 0:
		house_level = 2
	else:
		house_level = 1

	if old_level != house_level:
		update_visuals()

	var new_max = get_max_population(house_level)
	if current_population > new_max:
		var excess = current_population - new_max
		current_population = new_max
		Global.remove_population(excess)
		if Global.game_node:
			for i in range(excess):
				Global.game_node.spawn_returning_pop(global_position)

func update_visuals():
	if house_level == 0:
		sprite.modulate = Color(0.5, 0.5, 0.5) # Grey
	elif house_level == 1:
		sprite.modulate = Color(0.0, 1.0, 0.0) # Green
	elif house_level == 2:
		sprite.modulate = Color(1.0, 1.0, 0.0) # Yellow
	elif house_level == 3:
		sprite.modulate = Color(1.0, 0.5, 0.0) # Orange
