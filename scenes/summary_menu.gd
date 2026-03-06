extends Control

@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel
@onready var goals_label = $MarginContainer/VBoxContainer/GoalsRichTextLabel
@onready var story_label = $MarginContainer/VBoxContainer/StoryRichTextLabel
@onready var back_button = $MarginContainer/VBoxContainer/HBoxContainer/BackButton
@onready var next_button = $MarginContainer/VBoxContainer/HBoxContainer/NextButton

func _ready():
	var goals_text = "[b]Goals Reached:[/b]\n"
	for goal in Global.current_mission_goals:
		goals_text += "- " + goal["text"] + "\n"
	goals_label.text = goals_text

	story_label.text = "You did a great job! The population has grown, and your village is thriving. The goblins are happy with their new homes and ready for more challenges ahead. Excellent work, leader!"

	back_button.pressed.connect(_on_back_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)

	if Global.current_campaign_idx == -1 or Global.current_mission_idx == -1:
		next_button.disabled = true
	else:
		# Check if there's a next mission
		var missions = Global.campaigns[Global.current_campaign_idx]["missions"]
		if Global.current_mission_idx + 1 >= missions.size():
			next_button.disabled = true

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_next_button_pressed():
	Global.current_mission_idx += 1
	Global.current_mission_goals = Global.campaigns[Global.current_campaign_idx]["missions"][Global.current_mission_idx].get("structured_goals", [])

	# Load next mission challenges view (we will use campaign_menu with auto select or just go directly to game or a new intermediate screen)
	# For simplicity, we can load campaign menu with the new mission selected
	get_tree().change_scene_to_file("res://scenes/next_mission_menu.tscn")
