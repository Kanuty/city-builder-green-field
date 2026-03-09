extends Control

@onready var save_list = $VBoxContainer/ScrollContainer/SaveList
@onready var save_button = $VBoxContainer/HBoxContainer/SaveButton
@onready var save_name_edit = $VBoxContainer/SaveNameEdit
@onready var delete_confirm_dialog = $DeleteConfirmDialog

var save_files = []
var selected_save = ""
var save_to_delete = ""

func _ready():
	_refresh_save_list()
	save_name_edit.text = "Save_" + Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")


func _refresh_save_list():
	for child in save_list.get_children():
		child.queue_free()

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
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var select_btn = Button.new()
		select_btn.text = sf
		select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		select_btn.pressed.connect(func(): _on_save_selected(sf))
		hbox.add_child(select_btn)

		var del_btn = Button.new()
		del_btn.text = "X"
		del_btn.pressed.connect(func(): _on_delete_requested(sf))
		hbox.add_child(del_btn)

		save_list.add_child(hbox)

func _on_save_selected(save_name: String):
	selected_save = save_name
	save_name_edit.text = save_name

func _on_delete_requested(save_name: String):
	save_to_delete = save_name
	delete_confirm_dialog.dialog_text = "do you realy want to remove " + save_name + " save"
	delete_confirm_dialog.popup_centered()

func _on_delete_confirmed():
	if save_to_delete != "":
		var path = "user://saves/" + save_to_delete + ".json"
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

		if selected_save == save_to_delete:
			selected_save = ""
			save_name_edit.text = ""


		save_to_delete = ""
		_refresh_save_list()

func _on_save_button_pressed():
	var save_name = save_name_edit.text.strip_edges()
	if save_name == "":
		save_name = "save"
	Global.save_game(save_name)
	queue_free()

func _on_back_button_pressed():
	if get_tree().current_scene.name == "SaveGameMenu":
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		queue_free()