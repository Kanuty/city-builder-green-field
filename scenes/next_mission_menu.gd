extends Control

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var desc_label = $MarginContainer/VBoxContainer/DescRichTextLabel
@onready var goals_label = $MarginContainer/VBoxContainer/GoalsRichTextLabel
@onready var back_button = $MarginContainer/VBoxContainer/HBoxContainer/BackButton
@onready var start_button = $MarginContainer/VBoxContainer/HBoxContainer/StartButton

func _ready():
	var mission = Global.campaigns[Global.current_campaign_idx]["missions"][Global.current_mission_idx]
	title_label.text = mission["name"]
	desc_label.text = mission["description"]
	goals_label.text = mission["goals"]

	back_button.pressed.connect(_on_back_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")
