extends Control

@onready var workforce_label: Label = $Panel/MarginContainer/VBoxContainer/WorkforceLabel
@onready var population_label: Label = $Panel/MarginContainer/VBoxContainer/PopulationLabel
@onready var carrots_label: Label = $Panel/MarginContainer/VBoxContainer/CarrotsLabel
@onready var potato_label: Label = $Panel/MarginContainer/VBoxContainer/PotatoLabel
@onready var clay_label: Label = $Panel/MarginContainer/VBoxContainer/ClayLabel
@onready var pottery_label: Label = $Panel/MarginContainer/VBoxContainer/PotteryLabel
@onready var food_label: Label = $Panel/MarginContainer/VBoxContainer/FoodLabel
@onready var goals_label: RichTextLabel = $GoalsPanel/MarginContainer/GoalsRichTextLabel

func _ready():
	Global.workforce_changed.connect(_on_workforce_changed)
	Global.population_changed.connect(_on_population_changed)
	Global.goods_updated.connect(_on_goods_updated)
	_update_workforce_label(Global.available_workforce)
	_update_population_label(Global.total_population)
	_update_carrots_label(Global.inventory.get("Carrots", 0))
	_update_potato_label(Global.inventory.get("Potato", 0))
	_update_clay_label(Global.inventory.get("Clay", 0))
	_update_pottery_label(Global.inventory.get("Pottery", 0))
	_update_food_label(Global.inventory.get("Food", 0))

func _on_workforce_changed(new_value: int):
	_update_workforce_label(new_value)

func _on_population_changed(new_value: int):
	_update_population_label(new_value)

func _on_goods_updated(goods_id: String, new_value: int):
	if goods_id == "Carrots":
		_update_carrots_label(new_value)
	elif goods_id == "Potato":
		_update_potato_label(new_value)
	elif goods_id == "Clay":
		_update_clay_label(new_value)
	elif goods_id == "Pottery":
		_update_pottery_label(new_value)
	elif goods_id == "Food":
		_update_food_label(new_value)

func _update_workforce_label(value: int):
	workforce_label.text = "Workforce: " + str(value)

func _update_population_label(value: int):
	population_label.text = "Population: " + str(value)

func _update_carrots_label(value: int):
	carrots_label.text = "Carrots: " + str(value)

func _update_potato_label(value: int):
	potato_label.text = "Potato: " + str(value)

func _update_clay_label(value: int):
	clay_label.text = "Clay: " + str(value)

func _update_pottery_label(value: int):
	pottery_label.text = "Pottery: " + str(value)

func _update_food_label(value: int):
	food_label.text = "Food: " + str(value)

var goals_reached_popup_shown: bool = false
var goals_reached_popup_scene = preload("res://scenes/ui/goals_reached_popup.tscn")

func _process(delta):
	if Global.current_mission_goals.is_empty():
		$GoalsPanel.visible = false
		return

	$GoalsPanel.visible = true
	var goals_text = "[b]Goals:[/b]\n"
	var all_met = true

	for goal in Global.current_mission_goals:
		var is_met = false
		if goal["type"] == "population":
			if Global.total_population >= goal["target"]:
				is_met = true
		elif goal["type"] == "houses":
			var count = 0
			if Global.game_node and Global.game_node.buildings_parent:
				for building in Global.game_node.buildings_parent.get_children():
					if building.has_method("get_max_population") and building.house_level >= goal["level"]:
						count += 1
			if count >= goal["target"]:
				is_met = true

		if is_met:
			goals_text += "[color=green]- " + goal["text"] + "[/color]\n"
		else:
			goals_text += "- " + goal["text"] + "\n"
			all_met = false

	goals_label.text = goals_text

	if all_met and not goals_reached_popup_shown and Global.current_mission_goals.size() > 0:
		if not get_tree().paused:
			goals_reached_popup_shown = true
			_show_goals_reached_popup()

func _show_goals_reached_popup():
	var popup = goals_reached_popup_scene.instantiate()
	get_parent().add_child(popup)
	get_tree().paused = true
	popup.popup_closed.connect(_on_goals_reached_popup_closed)

func _on_goals_reached_popup_closed():
	if Global.game_node:
		Global.game_node.save_state()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/summary_menu.tscn")
