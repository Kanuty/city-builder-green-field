extends Node

signal workforce_changed(new_value)
signal goods_updated(goods_id, new_value)

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
