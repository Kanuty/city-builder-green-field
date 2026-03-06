extends Control

func _ready():
	var slider = $VBoxContainer/MusicVolumeSlider
	if MusicPlayer and slider:
		var db = MusicPlayer.volume_db
		var linear = db_to_linear(db)
		slider.value = linear

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_music_volume_slider_value_changed(value: float):
	if MusicPlayer:
		MusicPlayer.volume_db = linear_to_db(value)
