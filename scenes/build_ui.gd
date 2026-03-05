extends Control

signal building_selected(building_type: String)

func _on_farm_button_pressed():
	building_selected.emit("Farm")

func _on_magasine_button_pressed():
	building_selected.emit("Magasine")
