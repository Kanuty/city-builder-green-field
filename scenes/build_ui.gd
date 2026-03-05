extends Control

signal building_selected(building_type: String)

func _on_farm_button_pressed():
	building_selected.emit("Farm")
