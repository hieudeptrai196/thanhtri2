class_name ResourceCounter
extends HBoxContainer
## Icon + amount for one resource type. Uses ResourceType.icon when present, else a coloured tile.

var type: ResourceType

var _amount: Label


func setup(resource_type: ResourceType) -> void:
	type = resource_type
	add_theme_constant_override("separation", 6)
	var icon: Control
	if type.icon:
		var picture := TextureRect.new()
		picture.texture = type.icon
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon = picture
	else:
		var tile := Panel.new()
		tile.add_theme_stylebox_override("panel", UiStyle.box(type.color, type.color.lightened(0.35), 2, 5))
		icon = tile
	icon.custom_minimum_size = Vector2(22, 22)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.tooltip_text = tr(type.display_name)
	add_child(icon)
	_amount = UiStyle.label("0", 20)
	_amount.custom_minimum_size.x = 30
	add_child(_amount)


func set_amount(amount: int) -> void:
	_amount.text = str(amount)
