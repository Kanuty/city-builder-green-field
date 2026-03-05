extends Control

@onready var workforce_label: Label = $Panel/MarginContainer/VBoxContainer/WorkforceLabel
@onready var carrots_label: Label = $Panel/MarginContainer/VBoxContainer/CarrotsLabel

func _ready():
	Global.workforce_changed.connect(_on_workforce_changed)
	Global.carrots_changed.connect(_on_carrots_changed)
	_update_workforce_label(Global.available_workforce)
	_update_carrots_label(Global.total_carrots)

func _on_workforce_changed(new_value: int):
	_update_workforce_label(new_value)

func _on_carrots_changed(new_value: int):
	_update_carrots_label(new_value)

func _update_workforce_label(value: int):
	workforce_label.text = "Workforce: " + str(value)

func _update_carrots_label(value: int):
	carrots_label.text = "Carrots: " + str(value)
