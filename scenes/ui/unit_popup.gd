extends Control

@onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var picture_rect = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PictureRect
@onready var content_label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ContentLabel

var unit_node: Node3D

func setup(p_unit: Node3D):
	unit_node = p_unit

	if unit_node.has_method("get_unit_name"):
		title_label.text = unit_node.get_unit_name()
	elif "goods_type" in unit_node:
		title_label.text = "Transport Unit"
	elif "target_house" in unit_node:
		title_label.text = "Pop"
	else:
		title_label.text = "Unit"

	if unit_node.has_node("AnimatedSprite3D"):
		var anim_sprite = unit_node.get_node("AnimatedSprite3D")
		var frames = anim_sprite.sprite_frames
		var anim_name = anim_sprite.animation
		if frames and frames.has_animation(anim_name):
			var texture = frames.get_frame_texture(anim_name, 0)
			picture_rect.texture = texture

	content_label.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam."

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		close()

func close():
	get_tree().paused = false
	queue_free()
