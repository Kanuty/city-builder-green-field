extends Control

signal building_selected(building_type: String)
signal destruction_mode_toggled(active: bool)

@onready var destroy_button = $Panel/MarginContainer/VBoxContainer/DestroyButton
@onready var vbox_container = $Panel/MarginContainer/VBoxContainer

func _ready():
	var campaign_idx = Global.current_campaign_idx
	var mission_idx = Global.current_mission_idx

	for child in vbox_container.get_children():
		if child is Button and child.name != "DestroyButton":
			var building_name = child.text
			var is_available = Global.is_building_available(campaign_idx, mission_idx, building_name)
			child.visible = is_available

func _on_carrot_farm_button_pressed():
	untoggle_destroy_button()
	building_selected.emit("Carrot Farm")

func _on_potato_farm_button_pressed():
	untoggle_destroy_button()
	building_selected.emit("Potato Farm")

func _on_clay_pit_button_pressed():
	untoggle_destroy_button()
	building_selected.emit("Clay Pit")

func _on_pottery_house_button_pressed():
	untoggle_destroy_button()
	building_selected.emit("Pottery House")

func _on_warehouse_button_pressed():
	untoggle_destroy_button()
	building_selected.emit("Warehouse")

func _on_cooking_den_button_pressed():
	untoggle_destroy_button()
	building_selected.emit("Cooking Den")

func _on_house_button_pressed():
	untoggle_destroy_button()
	building_selected.emit("House")

func _on_destroy_button_toggled(button_pressed: bool):
	destruction_mode_toggled.emit(button_pressed)

func untoggle_destroy_button():
	if destroy_button.button_pressed:
		destroy_button.button_pressed = false
