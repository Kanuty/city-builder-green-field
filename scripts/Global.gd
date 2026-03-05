extends Node

signal workforce_changed(new_value)
signal goods_updated(goods_id, new_value)
signal magazine_registered()

var game_node: Node3D

const PRODUCIBLE_GOODS = {
	"Carrots": {
		"name": "Carrots",
		"base_price": 10
	}
}

var available_workforce: int = 100:
	set(value):
		available_workforce = max(0, value)
		workforce_changed.emit(available_workforce)

var inventory: Dictionary = {
	"Carrots": 0
}

var magazines: Array = []
var workforce_waiting_list: Array[Node] = []

func register_magazine(magazine):
	if not magazines.has(magazine):
		magazines.append(magazine)
		magazine_registered.emit()

func unregister_magazine(magazine):
	magazines.erase(magazine)

func find_nearest_magazine(position: Vector3) -> Node:
	var nearest_mag = null
	var min_dist = INF

	for mag in magazines:
		if mag.get_available_space() > 0:
			var dist = position.distance_to(mag.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_mag = mag

	return nearest_mag

func request_workers(amount: int, building: Node = null) -> int:
	var granted = min(amount, available_workforce)
	available_workforce -= granted

	if granted < amount and building != null:
		if not workforce_waiting_list.has(building):
			workforce_waiting_list.append(building)

	return granted

func return_workers(amount: int):
	available_workforce += amount
	_distribute_workforce()

func _distribute_workforce():
	if available_workforce <= 0 or workforce_waiting_list.is_empty():
		return

	# To prevent issues with modifying the array while iterating,
	# or multiple buildings grabbing the same workers,
	# we process the waiting list sequentially.
	var still_waiting = []
	for building in workforce_waiting_list:
		if is_instance_valid(building) and building.has_method("assign_workers"):
			var needed = building.get_needed_workers()
			if needed > 0:
				var granted = min(needed, available_workforce)
				available_workforce -= granted
				building.assign_workers(granted)

				if building.get_needed_workers() > 0:
					still_waiting.append(building)
			else:
				# Doesn't need workers anymore
				pass
		else:
			# Building is gone or invalid
			pass

		if available_workforce <= 0:
			# No more workers to distribute, but we might still have buildings in the list
			# we haven't reached yet.
			var current_index = workforce_waiting_list.find(building)
			for i in range(current_index + 1, workforce_waiting_list.size()):
				var b = workforce_waiting_list[i]
				if is_instance_valid(b) and not still_waiting.has(b):
					still_waiting.append(b)
			break

	workforce_waiting_list = still_waiting

func unregister_building(building: Node):
	workforce_waiting_list.erase(building)

func add_goods(goods_id: String, amount: int):
	if inventory.has(goods_id):
		inventory[goods_id] += amount
	else:
		inventory[goods_id] = amount
	goods_updated.emit(goods_id, inventory[goods_id])

func remove_goods(goods_id: String, amount: int):
	if inventory.has(goods_id):
		inventory[goods_id] = max(0, inventory[goods_id] - amount)
		goods_updated.emit(goods_id, inventory[goods_id])
