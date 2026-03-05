extends Control

@onready var workforce_label: Label = $Panel/MarginContainer/VBoxContainer/WorkforceLabel
@onready var carrots_label: Label = $Panel/MarginContainer/VBoxContainer/CarrotsLabel
@onready var potato_label: Label = $Panel/MarginContainer/VBoxContainer/PotatoLabel

func _ready():
	Global.workforce_changed.connect(_on_workforce_changed)
	Global.goods_updated.connect(_on_goods_updated)
	_update_workforce_label(Global.available_workforce)
	_update_carrots_label(Global.inventory.get("Carrots", 0))
	_update_potato_label(Global.inventory.get("Potato", 0))

func _on_workforce_changed(new_value: int):
	_update_workforce_label(new_value)

func _on_goods_updated(goods_id: String, new_value: int):
	if goods_id == "Carrots":
		_update_carrots_label(new_value)
	elif goods_id == "Potato":
		_update_potato_label(new_value)

func _update_workforce_label(value: int):
	workforce_label.text = "Workforce: " + str(value)

func _update_carrots_label(value: int):
	carrots_label.text = "Carrots: " + str(value)

func _update_potato_label(value: int):
	potato_label.text = "Potato: " + str(value)
