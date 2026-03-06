extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var timer = $Timer

func _ready():
	color_rect.visible = false
	if not Global.autosave_completed.is_connected(_show_message):
		Global.autosave_completed.connect(_show_message)

func _show_message():
	color_rect.visible = true
	timer.start()

func _on_timer_timeout():
	color_rect.visible = false
