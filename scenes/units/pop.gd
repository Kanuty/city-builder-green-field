extends Node3D

@export var speed: float = 2.0

var target_house: Node3D
var spawner_pos: Vector3
var returning: bool = false
var path: Array[Vector3] = []
var target_index: int = 0

@onready var animation_player: AnimatedSprite3D = $AnimatedSprite3D

func setup(p_target_house: Node3D, p_spawner_pos: Vector3, p_returning: bool):
	target_house = p_target_house
	spawner_pos = p_spawner_pos
	returning = p_returning

	var target_pos = spawner_pos if returning else target_house.global_position

	if Global.game_node:
		path = Global.game_node.get_path_to_destination(global_position, target_pos)
		if path.size() > 0:
			target_index = 0
			animation_player.play("moving")
		else:
			print("Pop: No path to target found!")
			call_deferred("_fail", "No path found")
	else:
		call_deferred("_fail", "No game node")

func _process(delta):
	if not returning and not is_instance_valid(target_house):
		returning = true
		if Global.game_node:
			path = Global.game_node.get_path_to_destination(global_position, spawner_pos)
			if path.size() > 0:
				target_index = 0
			else:
				_fail("No path back to spawner")
		return

	if path.size() == 0:
		return

	var target_pos = path[target_index]
	var direction = (target_pos - global_position).normalized()
	var distance = global_position.distance_to(target_pos)

	var move_dist = speed * delta
	if move_dist >= distance:
		global_position = target_pos
		target_index += 1
		if target_index >= path.size():
			_reach_destination()
	else:
		global_position += direction * move_dist

func _reach_destination():
	if returning:
		queue_free()
	else:
		if is_instance_valid(target_house):
			target_house.add_pop()
		queue_free()

func _fail(reason: String = "Unknown reason"):
	print("Pop failed: ", reason)
	if not returning and is_instance_valid(target_house):
		if target_house.has_method("cancel_reserve_pop"):
			target_house.cancel_reserve_pop()
	queue_free()
