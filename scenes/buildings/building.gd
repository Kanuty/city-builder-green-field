extends Node3D

enum State { NO_WORKERS, IDLE, PRODUCING }

@export var building_name: String = "Building"
@export var grid_size: Vector2i = Vector2i(1, 1)
@export var max_workers: int = 10
@export var goods_type: String = "Goods"
@export var max_capacity: int = 10
@export var production_base_time: float = 5.0

var current_state: State = State.NO_WORKERS
var current_workers: int = 0
var stored_goods: int = 0
var current_production_progress: float = 0.0

@onready var animation_player: AnimatedSprite3D = $AnimatedSprite3D
@onready var production_timer: Timer = $ProductionTimer

func _ready():
	update_state()
	# Try to get workers from global workforce
	current_workers = Global.request_workers(max_workers)
	update_state()

func update_state():
	var old_state = current_state

	if current_workers == 0:
		current_state = State.NO_WORKERS
	elif stored_goods >= max_capacity:
		current_state = State.IDLE
	else:
		current_state = State.PRODUCING

	if old_state != current_state:
		on_state_changed()

func on_state_changed():
	match current_state:
		State.NO_WORKERS:
			animation_player.play("no_workers")
			production_timer.stop()
		State.IDLE:
			animation_player.play("idle")
			production_timer.stop()
		State.PRODUCING:
			animation_player.play("producing")
			start_production()

func start_production():
	if current_workers > 0:
		var scale = float(current_workers) / float(max_workers)
		production_timer.wait_time = production_base_time / scale
		production_timer.start()

func _on_production_timer_timeout():
	if stored_goods < max_capacity:
		stored_goods += 1
		print(building_name, " produced ", goods_type, ". Total: ", stored_goods)
		if goods_type == "Carrots":
			Global.add_carrots(1)

	update_state()
	if current_state == State.PRODUCING:
		start_production()

func _exit_tree():
	Global.return_workers(current_workers)
