extends Node3D

enum State { NO_WORKERS, IDLE, PRODUCING }

@export var building_name: String = "Building"
@export var grid_size: Vector2i = Vector2i(1, 1)
@export var max_workers: int = 10
@export var goods_type: String = "Goods"
@export var max_capacity: int = 10
@export var production_base_time: float = 5.0
@export var spawn_units: bool = false
@export var unit_type: PackedScene
@export var max_spawned_units: int = 1
@export var consumes_goods: bool = false
@export var input_goods_type: String = ""
@export var secondary_input_goods_type: String = ""
@export var max_input_capacity: int = 10
@export var items_per_production: int = 1

var current_state: State = State.NO_WORKERS
var current_workers: int = 0
var stored_goods: int = 0
var stored_input_goods: int = 0
var stored_input_goods_types: Array[String] = []
var current_production_progress: float = 0.0

var current_warehouse_reservation: Node = null
var amount_reserved: int = 0
var current_spawned_units: int = 0

@onready var animation_player: AnimatedSprite3D = $AnimatedSprite3D
@onready var production_timer: Timer = $ProductionTimer
@onready var delivery_timer: Timer = $DeliveryTimer
@onready var timeout_timer: Timer = $TimeoutTimer

var input_sprites: Array = []
var output_sprites: Array = []

var potato_texture = preload("res://img/goods/potato.png")
var carrots_texture = preload("res://img/goods/carrots_01.png")
var clay_texture = preload("res://img/goods/clay.png")
var pottery_texture = preload("res://img/goods/pottery.png")
var food_texture = preload("res://img/goods/food.png")

func _ready():
	if not Global.PRODUCIBLE_GOODS.has(goods_type):
		var error_message = "Building error: %s tried to produce invalid goods type '%s'." % [building_name, goods_type]
		push_error(error_message)
		assert(Global.PRODUCIBLE_GOODS.has(goods_type), error_message)
		return

	Global.warehouse_registered.connect(_on_warehouse_registered)




	update_state()
	# Try to get workers from global workforce
	current_workers = Global.request_workers(max_workers)
	if not Global.workforce_changed.is_connected(_on_workforce_changed):
		Global.workforce_changed.connect(_on_workforce_changed)
	update_state()

func _on_workforce_changed(_new_workforce_total: int):
	if current_workers < max_workers and Global.available_workforce > 0:
		var needed = max_workers - current_workers
		var granted = Global.request_workers(needed)
		current_workers += granted
		update_state()

func _on_warehouse_registered():
	if  stored_goods > 0:
		try_send_to_warehouse()

func update_state():
	if stored_goods >= 4 or stored_goods >= max_capacity:
		try_send_to_warehouse()

	if consumes_goods and stored_input_goods < max_input_capacity:
		try_fetch_from_warehouse()

	var old_state = current_state

	if current_workers == 0:
		current_state = State.NO_WORKERS
	elif stored_goods >= max_capacity:
		current_state = State.IDLE
	elif consumes_goods and stored_input_goods < items_per_production:
		current_state = State.IDLE
	else:
		current_state = State.PRODUCING

	_update_visuals()

	if current_state == State.IDLE and consumes_goods and stored_input_goods < items_per_production:
		if timeout_timer.is_stopped():
			timeout_timer.start(5.0) # poll every 5 seconds

	if old_state != current_state:
		on_state_changed()

func _update_visuals():
	for s in input_sprites:
		s.queue_free()
	input_sprites.clear()

	for s in output_sprites:
		s.queue_free()
	output_sprites.clear()

	for i in range(stored_input_goods):
		var sprite = Sprite3D.new()
		sprite.axis = Vector3.AXIS_Y
		sprite.pixel_size = 0.001
		sprite.render_priority = 1
		sprite.position = Vector3(-0.3, 0.05 * i, 0)

		var type_to_render = input_goods_type
		if stored_input_goods_types.size() > i:
			type_to_render = stored_input_goods_types[i]

		if type_to_render == "Carrots":
			sprite.texture = carrots_texture
		elif type_to_render == "Potato":
			sprite.texture = potato_texture
		elif type_to_render == "Clay":
			sprite.texture = clay_texture
		elif type_to_render == "Pottery":
			sprite.texture = pottery_texture
		elif type_to_render == "Food":
			sprite.texture = food_texture
		else:
			sprite.texture = potato_texture
		add_child(sprite)
		input_sprites.append(sprite)

	for i in range(stored_goods):
		var sprite = Sprite3D.new()
		sprite.axis = Vector3.AXIS_Y
		sprite.pixel_size = 0.001
		sprite.render_priority = 1
		sprite.position = Vector3(0.3, 0.05 * i, 0)
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
			sprite.texture = potato_texture
		add_child(sprite)
		output_sprites.append(sprite)

func on_state_changed():
	match current_state:
		State.NO_WORKERS:
			animation_player.play("no_workers")
			production_timer.stop()
		State.IDLE:
			animation_player.play("idle")
			production_timer.stop()
		State.PRODUCING:
			animation_player.play("producing")
			start_production()

func remove_workers(amount: int) -> int:
	var to_remove = min(amount, current_workers)
	if to_remove > 0:
		current_workers -= to_remove
		update_state()
	return to_remove

func start_production():
	if current_workers > 0 and (not consumes_goods or stored_input_goods >= items_per_production):
		var scale = float(current_workers) / float(max_workers)
		production_timer.wait_time = production_base_time / scale
		production_timer.start()

func _on_production_timer_timeout():
	if stored_goods < max_capacity:
		if consumes_goods:
			stored_input_goods -= items_per_production
			for i in range(items_per_production):
				if stored_input_goods_types.size() > 0:
					stored_input_goods_types.pop_front()
		stored_goods += 1
		print(building_name, " produced ", goods_type, ". Total: ", stored_goods)

	update_state()
	if current_state == State.PRODUCING:
		start_production()

func try_send_to_warehouse():
	if current_warehouse_reservation != null or stored_goods == 0:
		return

	# Only send if we have at least 4 items, OR if we are at max capacity
	if stored_goods < 4 and stored_goods < max_capacity:
		return

	var warehouse = Global.find_nearest_warehouse(global_position)
	if warehouse:
		var available = warehouse.get_available_space()
		# Cannot send more than 4 items per transport
		var amount_to_send = min(stored_goods, available, 4)

		if amount_to_send > 0:
			if warehouse.reserve(amount_to_send):
				if spawn_units:
					if unit_type and current_spawned_units < max_spawned_units:
						var unit = unit_type.instantiate()
						get_parent().add_child(unit)
						unit.global_position = global_position
						unit.delivery_finished.connect(_on_unit_delivery_finished)
						unit.delivery_failed.connect(_on_unit_delivery_failed)
						unit.setup(self, warehouse, goods_type, amount_to_send, timeout_timer.wait_time)
						current_spawned_units += 1
						stored_goods -= amount_to_send # Immediately remove goods from building
						update_state()
						print(building_name, " spawned unit for delivery of ", amount_to_send)
						# If we want to spawn units but can't right now, we cancel the reservation we just made
						warehouse.cancel_reservation(amount_to_send)
					current_warehouse_reservation = warehouse
					amount_reserved = amount_to_send
					delivery_timer.start()
					timeout_timer.start()
					print(building_name, " started delivery of ", amount_to_send, " to ", warehouse.building_name)

func _on_unit_delivery_finished(amount_delivered: int):
	current_spawned_units -= 1
	update_state()
	print(building_name, " unit delivery finished. Amount: ", amount_delivered)

func _on_unit_delivery_failed(reason: String = "Unknown reason"):
	current_spawned_units -= 1
	update_state()
	print(building_name, " unit delivery failed. Reason: ", reason)

func receive_returned_goods(amount: int):
	stored_goods = min(max_capacity, stored_goods + amount)
	update_state()

func receive_fetched_goods(amount: int, fetched_goods_type: String = ""):
	stored_input_goods = min(max_input_capacity, stored_input_goods + amount)
	var type_to_add = fetched_goods_type if fetched_goods_type != "" else input_goods_type
	for i in range(amount):
		stored_input_goods_types.append(type_to_add)
	update_state()

func try_fetch_from_warehouse():
	if current_warehouse_reservation != null or current_spawned_units >= max_spawned_units:
		return

	var needed = max_input_capacity - stored_input_goods
	if needed <= 0:
		return

	var goods_to_fetch = input_goods_type
	var target_warehouse = null
	var min_dist = INF

	# If secondary input is defined, we can pick either
	# To make it simple, we just check warehouses for any of the required goods
	var search_types = [input_goods_type]
	if secondary_input_goods_type != "":
		search_types.append(secondary_input_goods_type)

	for warehouse in Global.warehouses:
		for g_type in search_types:
			var available_for_fetch = warehouse.get_available_for_fetch(g_type)
			if available_for_fetch > 0:
				var dist = global_position.distance_to(warehouse.global_position)
				if dist < min_dist:
					min_dist = dist
					target_warehouse = warehouse
					goods_to_fetch = g_type

	if target_warehouse:
		var available_amount = target_warehouse.get_available_for_fetch(goods_to_fetch)
		var amount_to_fetch = min(needed, available_amount, 4)
		if amount_to_fetch > 0:
			if target_warehouse.reserve_for_fetch(amount_to_fetch, goods_to_fetch):
				if unit_type:
					var unit = unit_type.instantiate()
					get_parent().add_child(unit)
					unit.global_position = global_position
					unit.delivery_finished.connect(_on_unit_delivery_finished)
					unit.delivery_failed.connect(_on_unit_delivery_failed)
					unit.setup_fetch(self, target_warehouse, goods_to_fetch, amount_to_fetch, timeout_timer.wait_time)
					current_spawned_units += 1
					print(building_name, " spawned unit to fetch ", amount_to_fetch, " ", goods_to_fetch)

func _on_delivery_timer_timeout():
	if is_instance_valid(current_warehouse_reservation):
		current_warehouse_reservation.receive_delivery(amount_reserved, goods_type)
		stored_goods -= amount_reserved
		timeout_timer.stop()
		print(building_name, " delivered ", amount_reserved, " to warehouse.")

	current_warehouse_reservation = null
	amount_reserved = 0
	update_state()

func _on_timeout_timer_timeout():
	if current_state == State.IDLE and consumes_goods and stored_input_goods < items_per_production:
		update_state() # Poll for goods if we are starved
		return

	if is_instance_valid(current_warehouse_reservation):
		print(building_name, " delivery timed out!")
		current_warehouse_reservation.cancel_reservation(amount_reserved)

	current_warehouse_reservation = null
	amount_reserved = 0
	delivery_timer.stop()

func _exit_tree():
	if is_instance_valid(current_warehouse_reservation):
		current_warehouse_reservation.cancel_reservation(amount_reserved)
	Global.return_workers(current_workers)
