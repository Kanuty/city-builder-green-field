extends Control

signal building_selected(building_type: String)
signal destruction_mode_toggled(active: bool)

@onready var destroy_button = $Panel/MarginContainer/VBoxContainer/DestroyButton

func _on_carrot_farm_button_pressed():
	untoggle_destroy_button()
	building_selected.emit("Carrot Farm")

func _on_potato_farm_button_pressed():
	untoggle_destroy_button()
	building_selected.emit("Potato Farm")

func _on_magasine_button_pressed():
	untoggle_destroy_button()
	building_selected.emit("Magasine")

func _on_destroy_button_toggled(button_pressed: bool):
	destruction_mode_toggled.emit(button_pressed)

func untoggle_destroy_button():
	if destroy_button.button_pressed:
		destroy_button.button_pressed = false
