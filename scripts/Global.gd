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
		var old_value = available_workforce
		available_workforce = max(0, value)
		if old_value != available_workforce:
			workforce_changed.emit.call_deferred(available_workforce)

var inventory: Dictionary = {
	"Carrots": 0
}

var magazines: Array = []

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

func request_workers(amount: int) -> int:
	var granted = min(amount, available_workforce)
	available_workforce -= granted
	return granted

func return_workers(amount: int):
	available_workforce += amount

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
