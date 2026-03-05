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

@onready var animation_player: AnimatedSprite3D = $AnimatedSprite3D
@onready var timeout_timer: Timer = $TimeoutTimer

func setup(p_spawner: Node3D, p_magazine: Node3D, p_goods_type: String, p_amount: int, p_timeout: float = 60.0):
	spawner = p_spawner
	magazine = p_magazine
	goods_type = p_goods_type
	amount = p_amount

	timeout_timer.wait_time = p_timeout

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
	if is_instance_valid(magazine):
		magazine.receive_delivery(amount, goods_type)
		delivery_finished.emit(amount)
		queue_free()
	else:
		_fail()

func _fail():
	if is_instance_valid(magazine):
		magazine.cancel_reservation(amount)
	delivery_failed.emit()
	queue_free()

func _on_timeout_timer_timeout():
	print("Unit: Delivery timed out!")
	_fail()
