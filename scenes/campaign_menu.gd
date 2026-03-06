extends Control

@onready var campaign_list = $MarginContainer/HBoxContainer/LeftPanel/CampaignList
@onready var mission_list = $MarginContainer/HBoxContainer/LeftPanel/MissionList
@onready var title_label = $MarginContainer/HBoxContainer/RightPanel/MissionTitle
@onready var desc_label = $MarginContainer/HBoxContainer/RightPanel/MissionDescription
@onready var goals_label = $MarginContainer/HBoxContainer/RightPanel/MissionGoals
@onready var go_button = $MarginContainer/HBoxContainer/RightPanel/HBoxContainer/GoButton

var campaigns = Global.campaigns

var selected_campaign_idx = -1
var selected_mission_idx = -1

func _ready():
	for campaign in campaigns:
		campaign_list.add_item(campaign["name"])

	_clear_mission_details()
	go_button.disabled = true

func _on_campaign_list_item_selected(index):
	selected_campaign_idx = index
	selected_mission_idx = -1
	mission_list.clear()
	_clear_mission_details()
	go_button.disabled = true

	var max_unlocked = Global.unlocked_missions.get(index, -1)
	var missions = campaigns[index]["missions"]
	for i in range(missions.size()):
		mission_list.add_item(missions[i]["name"])
		if i > max_unlocked:
			mission_list.set_item_disabled(i, true)

func _on_mission_list_item_selected(index):
	if mission_list.is_item_disabled(index):
		# Prevent selecting if it's disabled (in case UI somehow allows it)
		mission_list.deselect(index)
		return
	selected_mission_idx = index
	var mission = campaigns[selected_campaign_idx]["missions"][index]
	title_label.text = mission["name"]
	desc_label.text = mission["description"]
	goals_label.text = mission["goals"]
	go_button.disabled = false

func _clear_mission_details():
	title_label.text = "Select a mission"
	desc_label.text = ""
	goals_label.text = ""

func _on_go_button_pressed():
	if selected_campaign_idx != -1 and selected_mission_idx != -1:
		Global.current_campaign_idx = selected_campaign_idx
		Global.current_mission_idx = selected_mission_idx
		Global.current_mission_goals = campaigns[selected_campaign_idx]["missions"][selected_mission_idx].get("structured_goals", [])

		# If starting Mission 1, ignore any previous state for this campaign
		if selected_mission_idx == 0:
			var path = "user://campaign_%d_state.json" % selected_campaign_idx
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)

		get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_reset_progress_button_pressed():
	Global.reset_progress()
	if selected_campaign_idx != -1:
		_on_campaign_list_item_selected(selected_campaign_idx)
