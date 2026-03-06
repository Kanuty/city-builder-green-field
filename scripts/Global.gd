extends Node

signal workforce_changed(new_value)
signal population_changed(new_value)
signal goods_updated(goods_id, new_value)
signal warehouse_registered()

var game_node: Node3D

const PRODUCIBLE_GOODS = {
	"Carrots": {
		"name": "Carrots",
		"base_price": 10
	},
	"Potato": {
		"name": "Potato",
		"base_price": 12
	},
	"Clay": {
		"name": "Clay",
		"base_price": 5
	},
	"Pottery": {
		"name": "Pottery",
		"base_price": 20
	},
	"Food": {
		"name": "Food",
		"base_price": 15
	}
}

var available_workforce: int = 0:
	set(value):
		var old_value = available_workforce
		available_workforce = max(0, value)
		if old_value != available_workforce:
			workforce_changed.emit.call_deferred(available_workforce)

var total_population: int = 0:
	set(value):
		var old_value = total_population
		total_population = max(0, value)
		if old_value != total_population:
			population_changed.emit.call_deferred(total_population)

var inventory: Dictionary = {
	"Carrots": 0,
	"Potato": 0,
	"Clay": 0,
	"Pottery": 0,
	"Food": 0
}

var warehouses: Array = []

var current_mission_goals: Array = []

var current_campaign_idx: int = -1
var current_mission_idx: int = -1

var unlocked_missions: Dictionary = {}

var campaigns = [
	{
		"name": "Campaign 1",
		"missions": [
			{
				"name": "Mission 1",
				"description": "This is the first mission of the campaign.",
				"goals": "- Maintain population of at least 100\n- Have at least 4 houses level 2",
				"structured_goals": [
					{"type": "population", "target": 100, "text": "Maintain population of at least 100"},
					{"type": "houses", "level": 2, "target": 4, "text": "Have at least 4 houses level 2"}
				]
			},
			{
				"name": "Mission 2",
				"description": "The village is growing. Now we need to produce more food and attract even more goblins.",
				"goals": "- Maintain population of at least 200\n- Have at least 10 houses level 2",
				"structured_goals": [
					{"type": "population", "target": 200, "text": "Maintain population of at least 200"},
					{"type": "houses", "level": 2, "target": 10, "text": "Have at least 10 houses level 2"}
				]
			}
		]
	}
]

func _ready():
	load_progress()

func save_progress():
	var file = FileAccess.open("user://progress.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(unlocked_missions))

func load_progress():
	if FileAccess.file_exists("user://progress.json"):
		var file = FileAccess.open("user://progress.json", FileAccess.READ)
		if file:
			var data = file.get_as_text()
			var parsed = JSON.parse_string(data)
			if typeof(parsed) == TYPE_DICTIONARY:
				unlocked_missions = parsed
				# Ensure keys are integers since JSON parsing might make them strings
				var converted_dict = {}
				for key in unlocked_missions.keys():
					converted_dict[int(key)] = unlocked_missions[key]
				unlocked_missions = converted_dict

	# Initialize default if empty
	if unlocked_missions.is_empty():
		unlocked_missions[0] = 0
		for i in range(1, campaigns.size()):
			unlocked_missions[i] = -1

func reset_progress():
	unlocked_missions.clear()
	# Set all missions as unavailable but Mission 1 in Campaign 1
	# We interpret this as keeping campaign 0 mission 0 unlocked, and locking other campaigns
	unlocked_missions[0] = 0
	for i in range(1, campaigns.size()):
		unlocked_missions[i] = -1 # -1 means no mission unlocked in this campaign
	save_progress()

	# Clear any saved campaign state
	for i in range(campaigns.size()):
		var path = "user://campaign_%d_state.json" % i
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func has_saved_campaign_state(campaign_idx: int) -> bool:
	return FileAccess.file_exists("user://campaign_%d_state.json" % campaign_idx)

func save_campaign_state(campaign_idx: int, state_data: Dictionary):
	var file = FileAccess.open("user://campaign_%d_state.json" % campaign_idx, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(state_data))

func load_campaign_state(campaign_idx: int) -> Dictionary:
	var path = "user://campaign_%d_state.json" % campaign_idx
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var data = file.get_as_text()
			var parsed = JSON.parse_string(data)
			if typeof(parsed) == TYPE_DICTIONARY:
				return parsed
	return {}

func unlock_next_mission():
	if current_campaign_idx >= 0 and current_campaign_idx < campaigns.size():
		var max_unlocked = unlocked_missions.get(current_campaign_idx, 0)
		if current_mission_idx == max_unlocked:
			var missions_count = campaigns[current_campaign_idx]["missions"].size()
			if max_unlocked + 1 < missions_count:
				unlocked_missions[current_campaign_idx] = max_unlocked + 1
				save_progress()


func register_warehouse(warehouse):
	if not warehouses.has(warehouse):
		warehouses.append(warehouse)
		warehouse_registered.emit()

func unregister_warehouse(warehouse):
	warehouses.erase(warehouse)

func find_nearest_warehouse(position: Vector3) -> Node:
	var nearest_mag = null
	var min_dist = INF

	for mag in warehouses:
		if mag.get_available_space() > 0:
			var dist = position.distance_to(mag.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest_mag = mag

	return nearest_mag

func request_workers(amount: int) -> int:
	var granted = min(amount, available_workforce)
	available_workforce -= granted
	return granted

func return_workers(amount: int):
	available_workforce += amount

func add_population(amount: int):
	total_population += amount
	available_workforce += amount

func remove_population(amount: int):
	total_population -= amount
	available_workforce -= amount

	if available_workforce < 0:
		var deficit = -available_workforce
		if game_node:
			var buildings = game_node.buildings_parent.get_children()
			for building in buildings:
				if deficit <= 0:
					break
				if building.has_method("remove_workers"):
					var removed = building.remove_workers(deficit)
					if removed > 0:
						deficit -= removed
						available_workforce += removed

		# If still negative despite all efforts, just clip it to 0
		if available_workforce < 0:
			available_workforce = 0

func add_goods(goods_id: String, amount: int):
	if inventory.has(goods_id):
		inventory[goods_id] += amount
	else:
		inventory[goods_id] = amount
	goods_updated.emit(goods_id, inventory[goods_id])

func remove_goods(goods_id: String, amount: int):
	if inventory.has(goods_id):
		inventory[goods_id] = max(0, inventory[goods_id] - amount)
		goods_updated.emit(goods_id, inventory[goods_id])
