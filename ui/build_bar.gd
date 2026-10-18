class_name BuildBar
extends HBoxContainer
## Bottom-centre strip of buildable structures: key number, icon, name and cost. Highlights the
## selected one and dims what the shared storage cannot pay for.

var _builder: Builder
var _storage: Inventory
var _slots: Array[PanelContainer] = []


func setup(builder: Builder, storage: Inventory) -> void:
	_builder = builder
	_storage = storage
	add_theme_constant_override("separation", 10)
	for i in StructureTypes.ALL.size():
		var slot := _make_slot(i, StructureTypes.ALL[i])
		add_child(slot)
		_slots.append(slot)


func _process(_delta: float) -> void:
	if _builder == null:
		return
	for i in _slots.size():
		var type := StructureTypes.ALL[i]
		var active := _builder.active_type() == type
		var carrying_it: bool = _builder.active_type() == type and _builder.get_parent().carried_type == type
		var affordable: bool = _storage.has_all(type.cost) or carrying_it
		_slots[i].add_theme_stylebox_override("panel", UiStyle.box(
			UiStyle.WOOD_LIGHT if active else Color(UiStyle.WOOD_DARK, 0.8),
			UiStyle.BRONZE_BRIGHT if active else UiStyle.BRONZE.darkened(0.35), 3 if active else 2, 8))
		_slots[i].modulate = Color.WHITE if affordable else Color(1, 1, 1, 0.5)


func _make_slot(index: int, type: StructureType) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(row)
	row.add_child(UiStyle.label(str(index + 1), 18, UiStyle.BRONZE_BRIGHT))
	var icon: Control
	if type.icon:
		var picture := TextureRect.new()
		picture.texture = type.icon
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon = picture
	else:
		var tile := Panel.new()
		tile.add_theme_stylebox_override("panel", UiStyle.box(type.color, type.color.lightened(0.3), 2, 5))
		icon = tile
	icon.custom_minimum_size = Vector2(26, 26)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var text := VBoxContainer.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_constant_override("separation", 0)
	text.add_child(UiStyle.label(tr(type.display_name), 16))
	text.add_child(UiStyle.label(ResourceTypes.format_amounts(type.cost), 14, UiStyle.BRONZE))
	row.add_child(text)
	return slot
