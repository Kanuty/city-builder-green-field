extends Node

signal workforce_changed(new_value)

var available_workforce: int = 100:
	set(value):
		available_workforce = max(0, value)
		workforce_changed.emit(available_workforce)

func request_workers(amount: int) -> int:
	var granted = min(amount, available_workforce)
	available_workforce -= granted
	return granted

func return_workers(amount: int):
	available_workforce += amount
