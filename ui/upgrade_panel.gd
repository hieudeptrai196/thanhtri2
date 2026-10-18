class_name UpgradePanel
extends PanelContainer
## Shop shown at upgrade stops. It only displays what can be bought and reports presses;
## the match decides whether a purchase actually happens.

signal tier_upgrade_requested
signal tower_requested
signal weapon_upgrade_requested(index: int)
signal depart_requested

const WEAPON_CARD_SCENE := preload("res://ui/weapon_card.tscn")

var _fortress: Fortress
var _tier_button: Button
var _tower_button: Button
var _cards_row: HBoxContainer
var _offers: Array[WeaponUpgrade] = []
var _cards: Array[WeaponCard] = []
var _chosen: int = -1


func setup(fortress: Fortress) -> void:
	_fortress = fortress
	_fortress.storage.changed.connect(refresh)


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.panel())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)

	box.add_child(UiStyle.label(tr("Điểm dừng — nâng cấp"), 28, UiStyle.BRONZE_BRIGHT))
	box.add_child(UiStyle.label(tr("Pháo đài"), 18, UiStyle.MUTED))
	_tier_button = _add_button(box, tier_upgrade_requested)
	_tower_button = _add_button(box, tower_requested)

	box.add_child(UiStyle.label(tr("Vũ khí — chọn 1 thẻ"), 18, UiStyle.MUTED))
	_cards_row = HBoxContainer.new()
	_cards_row.add_theme_constant_override("separation", 12)
	box.add_child(_cards_row)

	var depart := _add_button(box, depart_requested)
	depart.text = tr("Khởi hành  ▶  (Space)")
	UiStyle.apply_button(depart, UiStyle.BRONZE_BRIGHT)


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


func set_weapon_choice(index: int) -> void:
	_chosen = index
	refresh()


func refresh() -> void:
	if _fortress == null or not is_visible_in_tree():
		return
	var next := _fortress.get_next_tier()
	if next:
		_tier_button.text = tr("Nâng thân pháo đài lên %s (%d máu) — %s") % [
			tr(next.display_name), next.max_health, ResourceTypes.format_amounts(next.cost)]
		_tier_button.disabled = not _fortress.storage.has_all(next.cost)
	else:
		_tier_button.text = tr("Thân pháo đài đã ở cấp cao nhất")
		_tier_button.disabled = true

	var free_slots := _fortress.free_tower_slots()
	_tower_button.text = tr("Xây tháp (còn %d ô) — %s") % [
		free_slots, ResourceTypes.format_amounts(_fortress.tower_cost)]
	_tower_button.disabled = free_slots == 0 or not _fortress.storage.has_all(_fortress.tower_cost)

	for i in _cards.size():
		var card := _cards[i]
		card.disabled = _chosen != -1 or not _fortress.storage.has_all(_offers[i].cost)
		card.modulate = Color(1, 1, 1, 0.45) if card.disabled and _chosen != i else Color.WHITE
		card.set_chosen(_chosen == i)


func _add_button(parent: Control, pressed_signal: Signal) -> Button:
	var button := Button.new()
	button.add_theme_font_size_override("font_size", 20)
	UiStyle.apply_button(button)
	button.pressed.connect(pressed_signal.emit)
	parent.add_child(button)
	return button
