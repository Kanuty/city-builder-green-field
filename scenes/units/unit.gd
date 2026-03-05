extends Node3D

signal delivery_finished(amount)
signal delivery_failed()

@export var speed: float = 3.0

var spawner: Node3D
var magazine: Node3D
var goods_type: String
var amount: int

var path: Array[Vector3] = []
var target_index: int = 0
var returning: bool = false

@onready var animation_player: AnimatedSprite3D = $AnimatedSprite3D
@onready var timeout_timer: Timer = $TimeoutTimer

func setup(p_spawner: Node3D, p_magazine: Node3D, p_goods_type: String, p_amount: int, p_timeout: float = 60.0):
	spawner = p_spawner
	magazine = p_magazine
	goods_type = p_goods_type
	amount = p_amount

	timeout_timer.wait_time = p_timeout

	_update_visuals()

	if Global.game_node:
		path = Global.game_node.get_path_to_destination(global_position, magazine.global_position)
		if path.size() > 0:
			target_index = 0
			animation_player.play("moving")
			timeout_timer.start()
		else:
			print("Unit: No path to magazine found!")
			# Use call_deferred to avoid emitting signal during setup if it leads to immediate destruction/state change issues
			call_deferred("_fail")
	else:
		print("Unit: Global.game_node is null!")
		call_deferred("_fail")

func _process(delta):
	if not is_instance_valid(spawner):
		_fail() # spawner destroyed, unit dies and goods are lost
		return

	if not is_instance_valid(magazine) and not returning:
		# If we were heading to a magazine and it was destroyed, try to find a new one before returning
		var new_magazine = Global.find_nearest_magazine(global_position)
		if new_magazine:
			if new_magazine.reserve(amount):
				magazine = new_magazine
				path = Global.game_node.get_path_to_destination(global_position, magazine.global_position)
				target_index = 0
				return # Continue in next frame with new path

		start_return_to_spawner()

	if returning:
		# If we are returning to spawner, check if a new magazine became available
		var new_magazine = Global.find_nearest_magazine(global_position)
		if new_magazine:
			if new_magazine.reserve(amount):
				magazine = new_magazine
				returning = false
				path = Global.game_node.get_path_to_destination(global_position, magazine.global_position)
				target_index = 0
				return

	if path.size() == 0:
		return

	var target_pos = path[target_index]
	var direction = (target_pos - global_position).normalized()
	var distance = global_position.distance_to(target_pos)

	var move_dist = speed * delta
	if move_dist >= distance:
		global_position = target_pos
		target_index += 1
		if target_index >= path.size():
			_reach_destination()
	else:
		global_position += direction * move_dist

func _reach_destination():
	if returning:
		if is_instance_valid(spawner):
			spawner.receive_returned_goods(amount)
		delivery_failed.emit() # Consider it failed as it didn't reach magazine
		queue_free()
	elif is_instance_valid(magazine):
		magazine.receive_delivery(amount, goods_type)
		delivery_finished.emit(amount)
		queue_free()
	else:
		start_return_to_spawner()

func start_return_to_spawner():
	returning = true
	if Global.game_node and is_instance_valid(spawner):
		path = Global.game_node.get_path_to_destination(global_position, spawner.global_position)
		if path.size() > 0:
			target_index = 0
		else:
			_fail()
	else:
		_fail()

func _update_visuals():
	var color = Color.WHITE
	if goods_type == "Carrots":
		color = Color(1.0, 0.5, 0.0) # Orange
	elif goods_type == "Potato":
		color = Color(0.5, 0.35, 0.05) # Brownish

	for i in range(4):
		var item_node = get_node_or_null("Items/Item" + str(i + 1))
		if item_node:
			item_node.visible = i < amount
			item_node.modulate = color

func _fail():
	if not returning and is_instance_valid(magazine):
		magazine.cancel_reservation(amount)
	delivery_failed.emit()
	queue_free()

func _on_timeout_timer_timeout():
	print("Unit: Delivery timed out!")
	_fail()
