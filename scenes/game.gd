extends Node3D

@export var scroll_speed: float = 10.0
@export var border_margin: float = 20.0
@onready var camera: Camera3D = $Camera3D

var map_size: Vector2 = Vector2(20.0, 20.0)
var max_view_range: Vector2 = Vector2(40.0, 40.0)

func _process(delta):
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
		# In isometric orthogonal view, the camera's x axis is tilted.
		# For simple movement, we move in the world X and Z directions.
		camera.global_position += movement * scroll_speed * delta

		# Clamp the camera position.
		# Since map is 20x20 centered at (0,0), bounds are -10 to 10.
		# Max size 2x current size means 40x40 centered at (0,0), bounds are -20 to 20.
		camera.global_position.x = clamp(camera.global_position.x, -max_view_range.x / 2.0, max_view_range.x / 2.0)
		camera.global_position.z = clamp(camera.global_position.z, -max_view_range.y / 2.0, max_view_range.y / 2.0)
