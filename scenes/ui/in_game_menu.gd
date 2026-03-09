extends CanvasLayer

var save_game_scene = preload("res://scenes/save_game_menu.tscn")
var load_game_scene = preload("res://scenes/load_game_menu.tscn")
var options_scene = preload("res://scenes/options_menu.tscn")

func _ready():
	visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel"): # ESC key
		if get_tree().paused:
			if visible:
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
	var save_menu = save_game_scene.instantiate()
	add_child(save_menu)

func _on_load_button_pressed():
	var load_menu = load_game_scene.instantiate()
	add_child(load_menu)

func _on_options_button_pressed():
	var options_menu = options_scene.instantiate()
	add_child(options_menu)

func _on_exit_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
