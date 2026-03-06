extends Control

@onready var campaign_list = $MarginContainer/HBoxContainer/LeftPanel/CampaignList
@onready var mission_list = $MarginContainer/HBoxContainer/LeftPanel/MissionList
@onready var title_label = $MarginContainer/HBoxContainer/RightPanel/MissionTitle
@onready var desc_label = $MarginContainer/HBoxContainer/RightPanel/MissionDescription
@onready var goals_label = $MarginContainer/HBoxContainer/RightPanel/MissionGoals
@onready var go_button = $MarginContainer/HBoxContainer/RightPanel/HBoxContainer/GoButton

var campaigns = [
	{
		"name": "Campaign 1",
		"missions": [
			{
				"name": "Mission 1",
				"description": "This is the first mission of the campaign.",
				"goals": "- Build a farm\n- Gather 100 food"
			}
		]
	}
]

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

	var missions = campaigns[index]["missions"]
	for mission in missions:
		mission_list.add_item(mission["name"])

func _on_mission_list_item_selected(index):
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
		get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
