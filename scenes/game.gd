extends Node3D

@export var scroll_speed: float = 10.0
@export var border_margin: float = 20.0
@onready var camera: Camera3D = $Camera3D
@onready var buildings_parent: Node3D = $Buildings
@onready var placement_preview: MeshInstance3D = $PlacementPreview

var map_size: Vector2 = Vector2(20.0, 20.0)
var max_view_range: Vector2 = Vector2(40.0, 40.0)

var current_building_type: String = ""
var destruction_mode_active: bool = false
var occupied_tiles: Dictionary = {} # Vector2i -> Node3D
var navigation_grid: AStarGrid2D
var carrot_farm_scene = preload("res://scenes/buildings/carrot_farm.tscn")
var potato_farm_scene = preload("res://scenes/buildings/potato_farm.tscn")
var clay_pit_scene = preload("res://scenes/buildings/clay_pit.tscn")
var pottery_house_scene = preload("res://scenes/buildings/pottery_house.tscn")
var warehouse_scene = preload("res://scenes/buildings/warehouse.tscn")
var cooking_den_scene = preload("res://scenes/buildings/cooking_den.tscn")
var house_scene = preload("res://scenes/buildings/house.tscn")
var building_popup_scene = preload("res://scenes/ui/building_popup.tscn")
var pop_scene = preload("res://scenes/units/pop.tscn")

var spawner_pos: Vector3 = Vector3(-10, 0, -10)
var pop_spawn_timer: Timer

func _ready():
	Global.game_node = self

	$UI/BuildUI.destruction_mode_toggled.connect(_on_build_ui_destruction_mode_toggled)

	# Initialize Navigation
	navigation_grid = AStarGrid2D.new()
	navigation_grid.region = Rect2i(-int(map_size.x/2), -int(map_size.y/2), int(map_size.x), int(map_size.y))
	navigation_grid.cell_size = Vector2(1, 1)
	navigation_grid.update()

	# Set up Spawner
	var spawner_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1, 1, 1)
	spawner_mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0) # Red
	spawner_mesh.material_override = mat
	add_child(spawner_mesh)
	spawner_mesh.global_position = spawner_pos

	pop_spawn_timer = Timer.new()
	pop_spawn_timer.wait_time = 2.0
	pop_spawn_timer.autostart = true
	pop_spawn_timer.timeout.connect(_on_pop_spawn_timer_timeout)
	add_child(pop_spawn_timer)

	# Register existing buildings
	for building in buildings_parent.get_children():
		var size = building.get("grid_size") if "grid_size" in building else Vector2i(1, 1)
		var grid_pos = world_to_grid(building.global_position - Vector3(size.x / 2.0, 0, size.y / 2.0))

		# Ensure they are snapped to grid
		building.global_position = grid_to_world_sized(grid_pos, size)

		for x in range(size.x):
			for y in range(size.y):
				occupied_tiles[grid_pos + Vector2i(x, y)] = building

		update_navigation_for_building(grid_pos, size, true)

	placement_preview.visible = false

func _process(delta):
	handle_camera_movement(delta)

	if current_building_type != "":
		update_placement_preview()

func _unhandled_input(event):
	if current_building_type != "":
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				try_place_building()
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				cancel_build_mode()
		elif event.is_action_pressed("ui_cancel"):
			cancel_build_mode()
	elif destruction_mode_active:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				try_destroy_building()
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				$UI/BuildUI.untoggle_destroy_button()
		elif event.is_action_pressed("ui_cancel"):
			$UI/BuildUI.untoggle_destroy_button()
	else:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				try_show_building_info()

func handle_camera_movement(delta):
	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	var move_direction = Vector3.ZERO

	if mouse_pos.x < border_margin:
		move_direction.x -= 1
	elif mouse_pos.x > viewport_size.x - border_margin:
		move_direction.x += 1

	if mouse_pos.y < border_margin:
		move_direction.z -= 1
	elif mouse_pos.y > viewport_size.y - border_margin:
		move_direction.z += 1

	if move_direction != Vector3.ZERO:
		move_direction = move_direction.normalized()

		# Transform move_direction to camera space but projected on XZ plane
		var forward = -camera.global_transform.basis.z
		forward.y = 0
		forward = forward.normalized()

		var right = camera.global_transform.basis.x
		right.y = 0
		right = right.normalized()

		var movement = (right * move_direction.x + forward * -move_direction.z)

		camera.global_position += movement * scroll_speed * delta
		camera.global_position.x = clamp(camera.global_position.x, -max_view_range.x / 2.0, max_view_range.x / 2.0)
		camera.global_position.z = clamp(camera.global_position.z, -max_view_range.y / 2.0, max_view_range.y / 2.0)

func world_to_grid(world_pos: Vector3) -> Vector2i:
	return Vector2i(floor(world_pos.x), floor(world_pos.z))

func grid_to_world(grid_pos: Vector2i) -> Vector3:
	return grid_to_world_sized(grid_pos, Vector2i(1, 1))

func grid_to_world_sized(grid_pos: Vector2i, size: Vector2i) -> Vector3:
	return Vector3(grid_pos.x + size.x / 2.0, 0, grid_pos.y + size.y / 2.0)

func get_mouse_world_pos() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)

	# Plane at Y=0
	var plane = Plane(Vector3.UP, 0)
	var intersection = plane.intersects_ray(ray_origin, ray_direction)

	if intersection != null:
		return intersection
	return Vector3.ZERO

func update_placement_preview():
	var world_pos = get_mouse_world_pos()
	var size = get_current_building_size()
	var grid_pos = world_to_grid(world_pos - Vector3(size.x / 2.0, 0, size.y / 2.0) + Vector3(0.5, 0, 0.5))

	# Clamp to map bounds
	grid_pos.x = clamp(grid_pos.x, -int(map_size.x/2), int(map_size.x/2) - size.x)
	grid_pos.y = clamp(grid_pos.y, -int(map_size.y/2), int(map_size.y/2) - size.y)

	placement_preview.scale = Vector3(size.x, 1, size.y)
	placement_preview.global_position = grid_to_world_sized(grid_pos, size)
	placement_preview.visible = true

	var mat = placement_preview.get_surface_override_material(0)
	if mat == null:
		mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		placement_preview.set_surface_override_material(0, mat)

	if is_area_free(grid_pos, size):
		mat.albedo_color = Color(0, 0, 1, 0.5) # Blue
	else:
		mat.albedo_color = Color(1, 0, 0, 0.5) # Red

func is_tile_free(grid_pos: Vector2i) -> bool:
	return not occupied_tiles.has(grid_pos)

func is_area_free(grid_pos: Vector2i, size: Vector2i) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			if occupied_tiles.has(grid_pos + Vector2i(x, y)):
				return false
	return true

func get_current_building_size() -> Vector2i:
	if current_building_type == "Carrot Farm" or current_building_type == "Potato Farm" or current_building_type == "Clay Pit" or current_building_type == "Pottery House" or current_building_type == "Cooking Den" or current_building_type == "House":
		return Vector2i(1, 1)
	elif current_building_type == "Warehouse":
		return Vector2i(2, 2)
	return Vector2i(1, 1)

func try_place_building():
	var world_pos = get_mouse_world_pos()
	var size = get_current_building_size()
	var grid_pos = world_to_grid(world_pos - Vector3(size.x / 2.0, 0, size.y / 2.0) + Vector3(0.5, 0, 0.5))

	# Final check of bounds to be sure
	if grid_pos.x < -int(map_size.x/2) or grid_pos.x > int(map_size.x/2) - size.x or \
	   grid_pos.y < -int(map_size.y/2) or grid_pos.y > int(map_size.y/2) - size.y:
		return

	if is_area_free(grid_pos, size):
		place_building(grid_pos)

func place_building(grid_pos: Vector2i):
	var new_building
	if current_building_type == "Carrot Farm":
		new_building = carrot_farm_scene.instantiate()
	elif current_building_type == "Potato Farm":
		new_building = potato_farm_scene.instantiate()
	elif current_building_type == "Clay Pit":
		new_building = clay_pit_scene.instantiate()
	elif current_building_type == "Pottery House":
		new_building = pottery_house_scene.instantiate()
	elif current_building_type == "Warehouse":
		new_building = warehouse_scene.instantiate()
	elif current_building_type == "Cooking Den":
		new_building = cooking_den_scene.instantiate()
	elif current_building_type == "House":
		new_building = house_scene.instantiate()

	if new_building:
		var size = new_building.get("grid_size") if "grid_size" in new_building else Vector2i(1, 1)
		buildings_parent.add_child(new_building)
		new_building.global_position = grid_to_world_sized(grid_pos, size)

		for x in range(size.x):
			for y in range(size.y):
				occupied_tiles[grid_pos + Vector2i(x, y)] = new_building

		update_navigation_for_building(grid_pos, size, true)
		# Optionally exit build mode or stay for multiple placements
		# Let's stay in build mode for now as per "user selection" then "can build"

func update_navigation_for_building(grid_pos: Vector2i, size: Vector2i, solid: bool):
	if navigation_grid:
		for x in range(size.x):
			for y in range(size.y):
				navigation_grid.set_point_solid(grid_pos + Vector2i(x, y), solid)

func get_path_to_destination(start_world: Vector3, end_world: Vector3) -> Array[Vector3]:
	var path: Array[Vector3] = []
	if not navigation_grid:
		return path

	var start_grid = world_to_grid(start_world)
	var end_grid = world_to_grid(end_world)

	# Make sure start and end points are walkable for the path calculation
	var was_start_solid = navigation_grid.is_point_solid(start_grid)
	var was_end_solid = navigation_grid.is_point_solid(end_grid)

	navigation_grid.set_point_solid(start_grid, false)
	navigation_grid.set_point_solid(end_grid, false)

	var grid_path = navigation_grid.get_point_path(start_grid, end_grid)

	navigation_grid.set_point_solid(start_grid, was_start_solid)
	navigation_grid.set_point_solid(end_grid, was_end_solid)

	for point in grid_path:
		path.append(Vector3(point.x + 0.5, 0, point.y + 0.5))

	return path

func try_destroy_building():
	var world_pos = get_mouse_world_pos()
	var grid_pos = world_to_grid(world_pos)

	if occupied_tiles.has(grid_pos):
		var building = occupied_tiles[grid_pos]
		destroy_building(building)

func destroy_building(building):
	var size = building.get("grid_size") if "grid_size" in building else Vector2i(1, 1)
	var grid_pos = world_to_grid(building.global_position - Vector3(size.x / 2.0, 0, size.y / 2.0))

	for x in range(size.x):
		for y in range(size.y):
			occupied_tiles.erase(grid_pos + Vector2i(x, y))

	update_navigation_for_building(grid_pos, size, false)
	building.queue_free()

func try_show_building_info():
	var world_pos = get_mouse_world_pos()
	var grid_pos = world_to_grid(world_pos)

	if occupied_tiles.has(grid_pos):
		var building = occupied_tiles[grid_pos]
		show_building_info(building)

func _on_pop_spawn_timer_timeout():
	var valid_houses = []
	for tile_pos in occupied_tiles:
		var building = occupied_tiles[tile_pos]
		if is_instance_valid(building) and building.building_name == "House":
			if building.get_available_space() > 0:
				if not valid_houses.has(building):
					valid_houses.append(building)

	if valid_houses.size() > 0:
		var target_house = valid_houses[randi() % valid_houses.size()]
		target_house.reserve_pop()
		spawn_pop(target_house)

func spawn_pop(target_house: Node3D):
	if pop_scene:
		var pop = pop_scene.instantiate()
		add_child(pop)
		pop.global_position = spawner_pos
		pop.setup(target_house, spawner_pos, false)

func spawn_returning_pop(start_pos: Vector3):
	if pop_scene:
		var pop = pop_scene.instantiate()
		add_child(pop)
		pop.global_position = start_pos
		pop.setup(null, spawner_pos, true)

func show_building_info(building: Node3D):
	if get_tree().paused:
		return

	var popup = building_popup_scene.instantiate()
	$UI.add_child(popup)
	popup.setup(building)
	get_tree().paused = true

func cancel_build_mode():
	current_building_type = ""
	placement_preview.visible = false

func _on_build_ui_building_selected(building_type):
	if building_type != "":
		$UI/BuildUI.untoggle_destroy_button()
	current_building_type = building_type

func _on_build_ui_destruction_mode_toggled(active):
	destruction_mode_active = active
	if active:
		cancel_build_mode()
