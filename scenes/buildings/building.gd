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

var current_state: State = State.NO_WORKERS
var current_workers: int = 0
var stored_goods: int = 0
var current_production_progress: float = 0.0

var current_warehouse_reservation: Node = null
var amount_reserved: int = 0
var current_spawned_units: int = 0

@onready var animation_player: AnimatedSprite3D = $AnimatedSprite3D
@onready var production_timer: Timer = $ProductionTimer
@onready var delivery_timer: Timer = $DeliveryTimer
@onready var timeout_timer: Timer = $TimeoutTimer

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
	var old_state = current_state

	if current_workers == 0:
		current_state = State.NO_WORKERS
	elif stored_goods >= max_capacity:
		current_state = State.IDLE
	else:
		current_state = State.PRODUCING

	if old_state != current_state:
		on_state_changed()

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

func start_production():
	if current_workers > 0:
		var scale = float(current_workers) / float(max_workers)
		production_timer.wait_time = production_base_time / scale
		production_timer.start()

func _on_production_timer_timeout():
	if stored_goods < max_capacity:
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
					else:
						# If we want to spawn units but can't right now, we cancel the reservation we just made
						warehouse.cancel_reservation(amount_to_send)
				else:
					current_warehouse_reservation = warehouse
					amount_reserved = amount_to_send
					delivery_timer.start()
					timeout_timer.start()
					print(building_name, " started delivery of ", amount_to_send, " to ", warehouse.building_name)

func _on_unit_delivery_finished(amount_delivered: int):
	current_spawned_units -= 1
	update_state()
	print(building_name, " unit delivery finished. Amount: ", amount_delivered)

func _on_unit_delivery_failed():
	current_spawned_units -= 1
	update_state()
	print(building_name, " unit delivery failed.")

func receive_returned_goods(amount: int):
	stored_goods = min(max_capacity, stored_goods + amount)
	update_state()

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
