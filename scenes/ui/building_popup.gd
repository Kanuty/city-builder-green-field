extends Control

@onready var popup_panel = $PanelContainer
@onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var content_label = $PanelContainer/MarginContainer/VBoxContainer/ContentLabel

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Background dim
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	# Consume mouse events on bg to close
	bg.gui_input.connect(_on_bg_gui_input)
	add_child(bg)
	move_child(bg, 0)

	# Optional: click outside popup panel closes it, so bg receives inputs
	popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP

func setup(building: Node3D):
	if "building_name" in building:
		title_label.text = building.building_name
	else:
		title_label.text = "Building"

	var info_text = ""

	# Warehouse specific
	if "stored_items" in building:
		if building.stored_items.is_empty():
			info_text += "Empty\n"
		else:
			for g in building.stored_items.keys():
				info_text += str(g) + ": " + str(building.stored_items[g]) + "\n"

	# Producer/Consumer specific
	elif "stored_goods" in building and "goods_type" in building:
		# Show output goods
		if building.goods_type != "":
			info_text += "Stored " + building.goods_type + ": " + str(building.stored_goods)
			if "max_capacity" in building:
				info_text += " / " + str(building.max_capacity)
			info_text += "\n"

		# Show input goods
		if "consumes_goods" in building and building.consumes_goods:
			var in_goods = building.input_goods_type
			if in_goods != "":
				info_text += "Stored " + in_goods + ": " + str(building.stored_input_goods)
				if "max_input_capacity" in building:
					info_text += " / " + str(building.max_input_capacity)
				info_text += "\n"

	# House specific
	elif "stored_food" in building and "stored_pottery" in building:
		var level = building.house_level
		if level == 0:
			title_label.text = "Dugout"
		elif level == 1:
			title_label.text = "Mud hut"
		elif level == 2:
			title_label.text = "Mud cot"

		info_text += "House Level: " + str(level) + "\n"
		info_text += "Population: " + str(building.current_population) + " / " + str(building.get_max_population(level)) + "\n"
		info_text += "Food: " + str(building.stored_food)
		if "max_food_capacity" in building:
			info_text += " / " + str(building.max_food_capacity)
		info_text += "\n"
		info_text += "Pottery: " + str(building.stored_pottery)
		if "max_pottery_capacity" in building:
			info_text += " / " + str(building.max_pottery_capacity)
		info_text += "\n\n"

		if level == 0:
			info_text += "Without any food, we won't attract any goblins\n"
		elif level == 1:
			info_text += "Without pottery I can't store my goods! Me no like!\n"
		elif level == 2:
			info_text += "It is so boring here...\n"

	if info_text == "":
		info_text = "No goods stored."

	content_label.text = info_text

func _on_bg_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		close()
		# Stop event propagation
		get_viewport().set_input_as_handled()

func close():
	get_tree().paused = false
	queue_free()
