extends Control

signal popup_closed

@onready var popup_panel = $PanelContainer
@onready var close_button = $PanelContainer/MarginContainer/VBoxContainer/CloseButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	# Consume mouse events on bg to close
	bg.gui_input.connect(_on_bg_gui_input)
	add_child(bg)
	move_child(bg, 0)

	popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	close_button.pressed.connect(_on_close_button_pressed)

func _on_bg_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_close_button_pressed():
	close()

func close():
	popup_closed.emit()
	queue_free()
