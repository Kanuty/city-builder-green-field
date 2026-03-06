extends CanvasLayer

@onready var save_dialog = $SaveDialog
@onready var save_name_edit = $SaveDialog/VBoxContainer/SaveNameEdit

func _ready():
	visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel"): # ESC key
		if get_tree().paused:
			if visible and not save_dialog.visible:
				_resume_game()
		else:
			_pause_game()

func _pause_game():
	get_tree().paused = true
	visible = true

func _resume_game():
	get_tree().paused = false
	visible = false

func _on_resume_button_pressed():
	_resume_game()

func _on_save_button_pressed():
	save_name_edit.text = "Save_" + Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	save_dialog.popup_centered()

func _on_load_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/load_game_menu.tscn")

func _on_exit_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_save_dialog_confirmed():
	var save_name = save_name_edit.text.strip_edges()
	if save_name == "":
		save_name = "save"
	Global.save_game(save_name)
	_resume_game()
