extends Control

@onready var workforce_label: Label = $Panel/MarginContainer/WorkforceLabel

func _ready():
	Global.workforce_changed.connect(_on_workforce_changed)
	_update_label(Global.available_workforce)

func _on_workforce_changed(new_value: int):
	_update_label(new_value)

func _update_label(value: int):
	workforce_label.text = "Workforce: " + str(value)
