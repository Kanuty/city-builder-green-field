extends Node3D

@export var scroll_speed: float = 10.0
@export var border_margin: float = 20.0
@onready var camera: Camera3D = $Camera3D
@onready var buildings_parent: Node3D = $Buildings
@onready var placement_preview: MeshInstance3D = $PlacementPreview

var map_size: Vector2 = Vector2(20.0, 20.0)
var max_view_range: Vector2 = Vector2(40.0, 40.0)

var current_building_type: String = ""
var occupied_tiles: Dictionary = {} # Vector2i -> Node3D
var farm_scene = preload("res://scenes/buildings/farm.tscn")
var magasine_scene = preload("res://scenes/buildings/magasine.tscn")

func _ready():
	# Register existing buildings
	for building in buildings_parent.get_children():
		var size = building.get("grid_size") if "grid_size" in building else Vector2i(1, 1)
		var grid_pos = world_to_grid(building.global_position - Vector3(size.x / 2.0, 0, size.y / 2.0))

		# Ensure they are snapped to grid
		building.global_position = grid_to_world_sized(grid_pos, size)

		for x in range(size.x):
			for y in range(size.y):
				occupied_tiles[grid_pos + Vector2i(x, y)] = building

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

func handle_camera_movement(delta):
	var viewport_size = get_viewport().get_visible_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	var movement = Vector3.ZERO

	if mouse_pos.x < border_margin:
		movement.x -= 1
	elif mouse_pos.x > viewport_size.x - border_margin:
		movement.x += 1

	if mouse_pos.y < border_margin:
		movement.z -= 1
	elif mouse_pos.y > viewport_size.y - border_margin:
		movement.z += 1

	if movement != Vector3.ZERO:
		movement = movement.normalized()
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
	if current_building_type == "Farm":
		return Vector2i(1, 1)
	elif current_building_type == "Magasine":
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
	if current_building_type == "Farm":
		new_building = farm_scene.instantiate()
	elif current_building_type == "Magasine":
		new_building = magasine_scene.instantiate()

	if new_building:
		var size = new_building.get("grid_size") if "grid_size" in new_building else Vector2i(1, 1)
		buildings_parent.add_child(new_building)
		new_building.global_position = grid_to_world_sized(grid_pos, size)

		for x in range(size.x):
			for y in range(size.y):
				occupied_tiles[grid_pos + Vector2i(x, y)] = new_building
		# Optionally exit build mode or stay for multiple placements
		# Let's stay in build mode for now as per "user selection" then "can build"

func cancel_build_mode():
	current_building_type = ""
	placement_preview.visible = false

func _on_build_ui_building_selected(building_type):
	current_building_type = building_type
