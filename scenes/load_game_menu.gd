extends Control

@onready var save_list = $VBoxContainer/SaveList
@onready var load_button = $VBoxContainer/HBoxContainer/LoadButton

var save_files = []
var selected_save = ""

func _ready():
	_refresh_save_list()
	load_button.disabled = true

func _refresh_save_list():
	save_list.clear()
	save_files.clear()

	var dir = DirAccess.open("user://saves")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var save_name = file_name.replace(".json", "")
				save_files.append(save_name)
			file_name = dir.get_next()

	save_files.sort()
	save_files.reverse()
	for sf in save_files:
		save_list.add_item(sf)

func _on_save_list_item_selected(index):
	selected_save = save_files[index]
	load_button.disabled = false

func _on_load_button_pressed():
	if selected_save != "":
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		Global.load_game_request(selected_save)

func _on_back_button_pressed():
	if get_tree().current_scene.name == "LoadGameMenu":
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		queue_free()
