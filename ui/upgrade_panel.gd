class_name UpgradePanel
extends PanelContainer
## Shop shown at upgrade stops. It only displays what can be bought and reports button presses;
## the match decides whether a purchase actually happens.

signal tier_upgrade_requested
signal tower_requested
signal depart_requested

var _fortress: Fortress
var _tier_button: Button
var _tower_button: Button


func setup(fortress: Fortress) -> void:
	_fortress = fortress
	_fortress.storage.changed.connect(refresh)


func _ready() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var title := Label.new()
	title.text = tr("Điểm dừng — nâng cấp")
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	_tier_button = _add_button(box, tier_upgrade_requested)
	_tower_button = _add_button(box, tower_requested)
	box.add_child(HSeparator.new())
	_add_button(box, depart_requested).text = tr("Khởi hành (Space)")


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


# Buttons never take keyboard focus, so Space (ready) cannot accidentally press a purchase.
func _add_button(parent: Control, pressed_signal: Signal) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(pressed_signal.emit)
	parent.add_child(button)
	return button
