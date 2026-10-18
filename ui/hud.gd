class_name Hud
extends Control
## In-match HUD: fortress health + route progress (top), warrior health over its head,
## carried/stored resources (bottom left), toasts and hints. Layout lives in hud.tscn.

const TOAST_SECONDS := 2.5
## Height above the warrior's feet where its health bar floats.
const WARRIOR_BAR_HEIGHT := 2.4

var _fortress: Fortress
var _warrior: Warrior
var _carried_label: Label
var _carried: Array[ResourceCounter] = []
var _stored: Array[ResourceCounter] = []
var _toast_tween: Tween

@onready var _fortress_label: Label = %FortressLabel
@onready var _fortress_bar: ProgressBar = %FortressBar
@onready var _speed_label: Label = %SpeedLabel
@onready var _route_progress: RouteProgress = %RouteProgress
@onready var _toast: Label = %Toast
@onready var _center_message: Label = %CenterMessage
@onready var _repair_hint: Label = %RepairHint
@onready var _grid: GridContainer = %Grid
@onready var _warrior_bar: ProgressBar = %WarriorBar
@onready var _build_bar: BuildBar = %BuildBar
@onready var _radial_menu: RadialMenu = %RadialMenu
@onready var _noise_label: Label = %NoiseLabel
@onready var _noise_bar: ProgressBar = %NoiseBar
@onready var _divine_label: Label = %DivineLabel
@onready var _divine_bar: ProgressBar = %DivineBar

const NOISE_LEVEL_NAMES: Array[String] = ["Yên tĩnh", "Dò xét", "Bầy đàn", "Dữ dội", "TRUY ĐUỔI"]
var _noise: NoiseMeter


func _ready() -> void:
	$TopPanel.add_theme_stylebox_override("panel", UiStyle.hud_panel())
	$ResourcePanel.add_theme_stylebox_override("panel", UiStyle.hud_panel())
	UiStyle.apply_bar(_fortress_bar, Color(0.75, 0.3, 0.2))
	UiStyle.apply_bar(_warrior_bar, Color(0.3, 0.7, 0.35))
	UiStyle.apply_bar(_noise_bar, Color(0.75, 0.6, 0.25))
	UiStyle.apply_bar(_divine_bar, Color(0.45, 0.75, 1.0))
	for label in [_fortress_label, _speed_label, _toast, _center_message, _repair_hint, _noise_label, _divine_label]:
		label.add_theme_color_override("font_color", UiStyle.PARCHMENT)
		UiStyle.outline(label)
	_toast.add_theme_color_override("font_color", UiStyle.BRONZE_BRIGHT)
	_toast.modulate.a = 0.0


func setup(fortress: Fortress, warrior: Warrior, noise: NoiseMeter = null) -> void:
	_fortress = fortress
	_warrior = warrior
	_noise = noise
	_noise_bar.max_value = NoiseMeter.MAX
	_divine_bar.max_value = fortress.divine_crossbow.max_charge
	_route_progress.follower = fortress.follower
	_build_bar.setup(warrior.builder, fortress.storage)
	_radial_menu.setup(warrior.builder)

	_carried_label = UiStyle.label("", 18, UiStyle.MUTED)
	_grid.add_child(_carried_label)
	_grid.add_child(_make_counter_row(_carried))
	_grid.add_child(UiStyle.label(tr("Kho"), 18, UiStyle.MUTED))
	_grid.add_child(_make_counter_row(_stored))

	fortress.health.health_changed.connect(_on_fortress_health_changed)
	warrior.health.health_changed.connect(_on_warrior_health_changed)
	warrior.inventory.changed.connect(_refresh_resources)
	fortress.storage.changed.connect(_refresh_resources)
	fortress.service_zone.deposited.connect(_on_deposited)
	_on_fortress_health_changed(fortress.health.current, fortress.health.max_health)
	_on_warrior_health_changed(warrior.health.current, warrior.health.max_health)
	_refresh_resources()


func show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_SECONDS)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)


## Shows a centred message (e.g. a respawn countdown); empty text hides it.
func set_center_message(text: String) -> void:
	_center_message.text = text
	_center_message.visible = text != ""


func _process(_delta: float) -> void:
	if _fortress == null:
		return
	var speed_text := tr("Tốc độ %d%%") % roundi(_fortress.follower.speed_multiplier * 100.0)
	match _fortress.speed_mode:
		Fortress.SpeedMode.OVERDRIVE:
			speed_text += tr(" · TĂNG TỐC")
		Fortress.SpeedMode.OUT_OF_FUEL:
			speed_text += tr(" · HẾT THAN")
	_speed_label.text = speed_text
	_speed_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.3) if _fortress.speed_mode == Fortress.SpeedMode.OUT_OF_FUEL else (UiStyle.BRONZE_BRIGHT if _fortress.overdrive else UiStyle.PARCHMENT))
	_update_warrior_bar()
	_update_prompt()
	_update_noise_and_divine()


func _update_noise_and_divine() -> void:
	_noise_bar.get_parent().visible = _noise != null
	if _noise:
		var level := _noise.level()
		_noise_bar.value = _noise.value
		_noise_label.text = tr("Tiếng ồn: %s") % tr(NOISE_LEVEL_NAMES[level])
		_noise_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3) if level == NoiseMeter.Level.PURSUIT else UiStyle.PARCHMENT)
	var divine := _fortress.divine_crossbow
	_divine_bar.value = divine.charge
	_divine_label.text = tr("Nỏ thần — sẵn sàng (G)") if divine.is_ready() else tr("Nỏ thần %d%%") % roundi(divine.charge / divine.max_charge * 100.0)
	_divine_label.add_theme_color_override("font_color", UiStyle.BRONZE_BRIGHT if divine.is_ready() else UiStyle.PARCHMENT)


func _update_warrior_bar() -> void:
	var camera := get_viewport().get_camera_3d()
	_warrior_bar.visible = _warrior.is_alive and camera != null
	if _warrior_bar.visible:
		var head := camera.unproject_position(_warrior.global_position + Vector3(0.0, WARRIOR_BAR_HEIGHT, 0.0))
		_warrior_bar.position = head - _warrior_bar.size * 0.5
		_warrior_bar.visible = get_viewport_rect().has_point(head)


# One contextual prompt at a time: carrying > recovering > repairing.
func _update_prompt() -> void:
	var builder := _warrior.builder
	_repair_hint.visible = _warrior.is_alive
	if not _repair_hint.visible:
		return
	if _warrior.carried_type:
		_repair_hint.text = tr("Đang vác %s — click / E để đặt (không tốn tài nguyên)") % tr(_warrior.carried_type.display_name)
		return
	var blueprint := builder.hammer_target if builder.hammer_target else builder.network.nearest_blueprint(_warrior.global_position, builder.recover_range)
	if blueprint and not builder.is_placing():
		var name_text := tr(blueprint.type.display_name)
		if blueprint.starved and builder.hammer_target:
			_repair_hint.text = tr("Hết tài nguyên để xây %s — mang thêm về hoặc góp từ túi") % name_text
		else:
			_repair_hint.text = tr("Giữ E để xây %s — %d%%") % [name_text, roundi(blueprint.build_fraction() * 100.0)] + _helpers_text(blueprint)
		return
	if builder.recover_target:
		var progress := roundi(builder.recover_progress / builder.recover_hold_time * 100.0)
		var verb := tr("thu") if builder.recover_target.built else tr("dỡ bản vẽ")
		_repair_hint.text = tr("Giữ F để %s %s") % [verb, tr(builder.recover_target.type.display_name)] + (" (%d%%)" % progress if progress > 0 else "") + _helpers_text(builder.recover_target)
		return
	var damaged := _fortress.health.current < _fortress.health.max_health
	_repair_hint.visible = damaged and _fortress.service_zone.overlaps_body(_warrior)
	if not _repair_hint.visible:
		return
	if _fortress.storage.get_amount(_fortress.repair_resource.id) > 0:
		_repair_hint.text = tr("Giữ E để sửa pháo đài")
	else:
		_repair_hint.text = tr("Kho hết %s — cần mang về để sửa") % tr(_fortress.repair_resource.display_name)


func _helpers_text(structure: Structure) -> String:
	return tr(" · %d người") % structure.helpers if structure.helpers > 1 else ""


func _make_counter_row(counters: Array[ResourceCounter]) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for type in ResourceTypes.ALL:
		var counter := ResourceCounter.new()
		counter.setup(type)
		row.add_child(counter)
		counters.append(counter)
	return row


func _refresh_resources() -> void:
	_carried_label.text = tr("Mang %d/%d") % [_warrior.inventory.total(), _warrior.inventory.capacity]
	for counter in _carried:
		counter.set_amount(_warrior.inventory.get_amount(counter.type.id))
	for counter in _stored:
		counter.set_amount(_fortress.storage.get_amount(counter.type.id))


func _on_fortress_health_changed(current: float, maximum: float) -> void:
	_fortress_bar.max_value = maximum
	_fortress_bar.value = current
	_fortress_label.text = tr("Pháo đài %s %d/%d") % [tr(_fortress.get_tier().display_name), current, maximum]


func _on_warrior_health_changed(current: float, maximum: float) -> void:
	_warrior_bar.max_value = maximum
	_warrior_bar.value = current


func _on_deposited(contents: Dictionary) -> void:
	show_toast(tr("Nộp vào kho: %s") % ResourceTypes.format_amounts(contents))
