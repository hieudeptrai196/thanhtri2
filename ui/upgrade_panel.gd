class_name UpgradePanel
extends PanelContainer
## Shop shown at upgrade stops. It only displays what can be bought and reports presses;
## the match decides whether a purchase actually happens.

signal tier_upgrade_requested
signal fortress_upgrade_requested(upgrade: FortressUpgrade)
signal weapon_upgrade_requested(index: int)
signal route_requested(index: int)
signal depart_requested

const WEAPON_CARD_SCENE := preload("res://ui/weapon_card.tscn")

var _fortress: Fortress
var _tier_button: Button
var _upgrade_buttons: Dictionary = {}
var _cards_row: HBoxContainer
var _offers: Array[WeaponUpgrade] = []
var _cards: Array[WeaponCard] = []
var _chosen: int = -1
var _routes_row: HBoxContainer
var _route_cards: Array[Button] = []
var _route_choice: int = -1
var _depart: Button


func setup(fortress: Fortress) -> void:
	_fortress = fortress
	_fortress.storage.changed.connect(refresh)


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.panel())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	box.add_child(UiStyle.label(tr("Điểm dừng — nâng cấp"), 28, UiStyle.BRONZE_BRIGHT))
	box.add_child(UiStyle.label(tr("Chọn tuyến tiếp theo"), 18, UiStyle.MUTED))
	_routes_row = HBoxContainer.new()
	_routes_row.add_theme_constant_override("separation", 12)
	box.add_child(_routes_row)

	# Two columns keep the panel short enough for 720p: fortress on the left, weapon cards on the right.
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	box.add_child(columns)
	var fortress_column := VBoxContainer.new()
	fortress_column.add_theme_constant_override("separation", 8)
	fortress_column.custom_minimum_size.x = 380.0
	columns.add_child(fortress_column)
	var weapon_column := VBoxContainer.new()
	weapon_column.add_theme_constant_override("separation", 8)
	weapon_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(weapon_column)

	fortress_column.add_child(UiStyle.label(tr("Pháo đài"), 18, UiStyle.MUTED))
	_tier_button = _add_button(fortress_column, tier_upgrade_requested)
	for upgrade in FortressUpgrades.ALL:
		var button := _add_button(fortress_column, fortress_upgrade_requested)
		button.pressed.disconnect(fortress_upgrade_requested.emit)
		button.pressed.connect(fortress_upgrade_requested.emit.bind(upgrade))
		button.tooltip_text = tr(upgrade.description)
		_upgrade_buttons[upgrade] = button

	weapon_column.add_child(UiStyle.label(tr("Vũ khí — chọn 1 thẻ"), 18, UiStyle.MUTED))
	_cards_row = HBoxContainer.new()
	_cards_row.add_theme_constant_override("separation", 12)
	weapon_column.add_child(_cards_row)

	_depart = _add_button(box, depart_requested)
	set_ready_count(0, 1, false)


func set_weapon_offers(offers: Array[WeaponUpgrade]) -> void:
	_offers = offers
	_chosen = -1
	for card in _cards:
		card.queue_free()
	_cards.clear()
	for i in offers.size():
		var card: WeaponCard = WEAPON_CARD_SCENE.instantiate()
		_cards_row.add_child(card)
		card.show_upgrade(offers[i])
		card.pressed.connect(weapon_upgrade_requested.emit.bind(i))
		_cards.append(card)
	refresh()


func set_route_offers(offers: Array[RouteType]) -> void:
	for card in _route_cards:
		card.queue_free()
	_route_cards.clear()
	for i in offers.size():
		var card := _make_route_card(offers[i])
		card.pressed.connect(route_requested.emit.bind(i))
		_routes_row.add_child(card)
		_route_cards.append(card)
	set_route_choice(-1)


func set_route_choice(index: int) -> void:
	_route_choice = index
	for i in _route_cards.size():
		var chosen := i == index
		_route_cards[i].add_theme_stylebox_override("normal", UiStyle.card_frame(UiStyle.BRONZE_BRIGHT if chosen else UiStyle.BRONZE.darkened(0.25), 4 if chosen else 2,
			Color.WHITE, UiStyle.WOOD_LIGHT if chosen else UiStyle.WOOD))


func set_weapon_choice(index: int) -> void:
	_chosen = index
	refresh()


## Co-op: the fortress leaves once everyone is ready. Solo shows the plain depart button.
func set_ready_count(ready: int, total: int, me_ready: bool) -> void:
	if total <= 1:
		_depart.text = tr("Khởi hành  ▶  (Space)")
	elif me_ready:
		_depart.text = tr("Đã sẵn sàng — chờ đồng đội (%d/%d)") % [ready, total]
	else:
		_depart.text = tr("Sẵn sàng khởi hành  ▶  (Space) — %d/%d") % [ready, total]
	_depart.disabled = me_ready
	UiStyle.apply_button(_depart, UiStyle.BRONZE_BRIGHT)


func refresh() -> void:
	if _fortress == null or not is_visible_in_tree():
		return
	var next := _fortress.get_next_tier()
	if next:
		_tier_button.text = tr("Nâng thân pháo đài lên %s (%d máu) — %s") % [
			tr(next.display_name), next.max_health, ResourceTypes.format_amounts(_fortress.tier_cost(next))]
		_tier_button.disabled = not _fortress.storage.has_all(_fortress.tier_cost(next))
	else:
		_tier_button.text = tr("Thân pháo đài đã ở cấp cao nhất")
		_tier_button.disabled = true


	for upgrade: FortressUpgrade in _upgrade_buttons:
		var button: Button = _upgrade_buttons[upgrade]
		var level := _fortress.upgrade_level(upgrade.id)
		var cost := _fortress.next_upgrade_cost(upgrade)
		if cost.is_empty():
			button.text = tr("%s — cấp tối đa") % tr(upgrade.display_name)
			button.disabled = true
		else:
			button.text = tr("%s cấp %d — %s") % [tr(upgrade.display_name), level + 1, ResourceTypes.format_amounts(cost)]
			button.disabled = not _fortress.storage.has_all(cost)

	for i in _cards.size():
		var card := _cards[i]
		card.disabled = _chosen != -1 or not _fortress.storage.has_all(_offers[i].cost)
		card.modulate = Color(1, 1, 1, 0.45) if card.disabled and _chosen != i else Color.WHITE
		card.set_chosen(_chosen == i)


# Wide card: route name and what it trades off. Uses RouteType.art later when it exists.
func _make_route_card(type: RouteType) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(0, 74)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.apply_card(card)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	column.add_child(UiStyle.label(tr(type.display_name), 19, UiStyle.BRONZE_BRIGHT))
	var description := UiStyle.label(tr(type.description), 14)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description)
	return card


func _add_button(parent: Control, pressed_signal: Signal) -> Button:
	var button := Button.new()
	button.add_theme_font_size_override("font_size", 17)
	UiStyle.apply_button(button)
	button.pressed.connect(pressed_signal.emit)
	parent.add_child(button)
	return button
