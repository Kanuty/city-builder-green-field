extends Node

signal workforce_changed(new_value)
signal population_changed(new_value)
signal goods_updated(goods_id, new_value)
signal warehouse_registered()
signal autosave_completed()

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
var available_buildings_config: Dictionary = {}

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
	load_buildings_config()

func load_buildings_config():
	if FileAccess.file_exists("res://buildings_config.json"):
		var file = FileAccess.open("res://buildings_config.json", FileAccess.READ)
		if file:
			var data = file.get_as_text()
			var parsed = JSON.parse_string(data)
			if typeof(parsed) == TYPE_DICTIONARY:
				available_buildings_config = parsed

func is_building_available(campaign_idx: int, mission_idx: int, building_name: String) -> bool:
	var c_key = str(campaign_idx)
	var m_key = str(mission_idx)
	if available_buildings_config.has(c_key):
		if available_buildings_config[c_key].has(m_key):
			var allowed = available_buildings_config[c_key][m_key]
			if typeof(allowed) == TYPE_ARRAY:
				return building_name in allowed
	return true

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


func get_save_data() -> Dictionary:
	var buildings_data = []
	var units_data = []
	if is_instance_valid(game_node):
		for building in game_node.buildings_parent.get_children():
			var b_data = {
				"scene_path": building.scene_file_path,
				"global_position_x": building.global_position.x,
				"global_position_y": building.global_position.y,
				"global_position_z": building.global_position.z,
			}
			buildings_data.append(b_data)

		for unit in get_tree().get_nodes_in_group("units"):
			var u_data = {
				"scene_path": unit.scene_file_path,
				"global_position_x": unit.global_position.x,
				"global_position_y": unit.global_position.y,
				"global_position_z": unit.global_position.z,
				"is_pop": unit.has_method("setup") # Pop units have setup method, Transporters have setup_delivery/setup_fetch
			}
			units_data.append(u_data)

	var data = {
		"available_workforce": available_workforce,
		"total_population": total_population,
		"inventory": inventory,
		"current_mission_goals": current_mission_goals,
		"current_campaign_idx": current_campaign_idx,
		"current_mission_idx": current_mission_idx,
		"unlocked_missions": unlocked_missions,
		"buildings": buildings_data,
		"units": units_data
	}
	return data

func save_game(save_name: String):
	var data = get_save_data()
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")

	var file = FileAccess.open("user://saves/" + save_name + ".json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game_request(save_name: String):
	call_deferred("_do_load_game", save_name)

func _do_load_game(save_name: String):


	var current_scene_name = get_tree().current_scene.name
	if current_scene_name != "Game":
		# wait for scene change instead of arbitrary timeout
		await get_tree().process_frame
		while get_tree().current_scene.name != "Game":
			await get_tree().process_frame
		# wait another frame for ready to complete
		await get_tree().process_frame


	var file = FileAccess.open("user://saves/" + save_name + ".json", FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if typeof(data) == TYPE_DICTIONARY:
			available_workforce = data.get("available_workforce", 0)
			total_population = data.get("total_population", 0)
			inventory = data.get("inventory", {
				"Carrots": 0, "Potato": 0, "Clay": 0, "Pottery": 0, "Food": 0
			})
			current_mission_goals = data.get("current_mission_goals", [])
			current_campaign_idx = data.get("current_campaign_idx", -1)
			current_mission_idx = data.get("current_mission_idx", -1)

			var ulm = data.get("unlocked_missions", {})
			unlocked_missions.clear()
			for k in ulm.keys():
				unlocked_missions[int(k)] = ulm[k]

			if is_instance_valid(game_node):
				# Need to reconstruct buildings
				for child in game_node.buildings_parent.get_children():
					child.queue_free()

				# Wait a frame for children to free
				await get_tree().process_frame

				# Clear occupied_tiles and navigation_grid
				game_node.occupied_tiles.clear()
				game_node.navigation_grid.update()

				# Remove existing units
				for unit in get_tree().get_nodes_in_group("units"):
					unit.queue_free()

				var buildings = data.get("buildings", [])
				for b_data in buildings:
					var scene = load(b_data["scene_path"])
					if scene:
						var inst = scene.instantiate()
						inst.scene_file_path = b_data["scene_path"]
						inst.global_position = Vector3(
							b_data["global_position_x"],
							b_data["global_position_y"],
							b_data["global_position_z"]
						)
						game_node.buildings_parent.add_child(inst)
						var size = inst.get("grid_size") if "grid_size" in inst else Vector2i(1, 1)
						var grid_pos = game_node.world_to_grid(inst.global_position - Vector3(size.x / 2.0, 0, size.y / 2.0))
						for x in range(size.x):
							for y in range(size.y):
								game_node.occupied_tiles[grid_pos + Vector2i(x, y)] = inst
						game_node.update_navigation_for_building(grid_pos, size, true)

				var units = data.get("units", [])
				for u_data in units:
					var scene_path = u_data.get("scene_path", "")
					if scene_path == "":
						if u_data.get("is_pop", false):
							scene_path = "res://scenes/units/pop.tscn"
						else:
							scene_path = "res://scenes/units/unit.tscn"

					var pos = Vector3(u_data["global_position_x"], u_data["global_position_y"], u_data["global_position_z"])

					var unit_scene = load(scene_path)
					if unit_scene:
						if u_data.get("is_pop", false):
							if game_node.has_method("spawn_returning_pop"):
								game_node.spawn_returning_pop(pos)
						else:
							# For now just instantiating a dummy unit that returns, as reconstructing full delivery state is complex
							var inst = unit_scene.instantiate()
							inst.scene_file_path = scene_path
							inst.global_position = pos
							game_node.add_child(inst)
							inst.returning = true
							if game_node.buildings_parent.get_child_count() > 0:
								inst.spawner = game_node.buildings_parent.get_child(0) # send somewhere to despawn or wait

			# Re-emit signals
			workforce_changed.emit(available_workforce)
			population_changed.emit(total_population)
			for k in inventory.keys():
				goods_updated.emit(k, inventory[k])

func save_campaign_state():
	if current_campaign_idx >= 0:
		var data = get_save_data()
		var file = FileAccess.open("user://campaign_" + str(current_campaign_idx) + "_state.json", FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(data))

func load_campaign_state() -> Dictionary:
	if current_campaign_idx >= 0:
		var path = "user://campaign_" + str(current_campaign_idx) + "_state.json"
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			if file:
				var data = JSON.parse_string(file.get_as_text())
				if typeof(data) == TYPE_DICTIONARY:
					return data
	return {}

func clear_campaign_state():
	if current_campaign_idx >= 0:
		var path = "user://campaign_" + str(current_campaign_idx) + "_state.json"
		if FileAccess.file_exists(path):
			var dir = DirAccess.open("user://")
			dir.remove("campaign_" + str(current_campaign_idx) + "_state.json")
