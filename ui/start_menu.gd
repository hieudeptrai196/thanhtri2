class_name StartMenu
extends Control
## Start screen: play a random road or today's daily challenge, with local records, the co-op
## lobby (open a room / join one by address), and the language picker (shown alone on the very
## first launch).
## Only reports the choice; the match starts the run.

signal play_requested
signal daily_requested
signal host_requested
signal join_requested(address: String)
## The host starts the shared run.
signal online_start_requested
signal leave_requested

@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _play: Button = %Play
@onready var _daily: Button = %Daily
@onready var _records: Label = %Records
@onready var _language_title: Label = %LanguageTitle
@onready var _languages: HBoxContainer = %Languages

var _language_buttons: Dictionary = {}
# Co-op lobby, built in code under the main column.
var _coop: Button
var _lobby: VBoxContainer
var _lobby_title: Label
var _host: Button
var _address: LineEdit
var _join: Button
var _lobby_status: Label
var _start: Button
var _back: Button


func _ready() -> void:
	_panel.add_theme_stylebox_override("panel", UiStyle.panel())
	_title.add_theme_color_override("font_color", UiStyle.BRONZE_BRIGHT)
	UiStyle.outline(_title, 10)
	_subtitle.add_theme_color_override("font_color", UiStyle.PARCHMENT)
	_records.add_theme_color_override("font_color", UiStyle.MUTED.lightened(0.3))
	UiStyle.apply_button(_play, UiStyle.BRONZE_BRIGHT)
	UiStyle.apply_button(_daily)
	_play.pressed.connect(play_requested.emit)
	_daily.pressed.connect(daily_requested.emit)
	_build_lobby()
	_language_title.add_theme_color_override("font_color", UiStyle.PARCHMENT)
	for code in Locales.SUPPORTED:
		var button := Button.new()
		button.text = Locales.SUPPORTED[code]  # each language names itself, untranslated
		button.custom_minimum_size = Vector2(150, 40)
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(_on_language_picked.bind(code))
		_languages.add_child(button)
		_language_buttons[code] = button
	hide()


func open() -> void:
	var first_launch := not Locales.has_chosen()
	for control in [_subtitle, _play, _daily, _coop, _records, _language_title, _languages]:
		control.visible = not first_launch
	_language_title.visible = true
	_languages.visible = true
	_lobby.visible = false
	_language_title.text = tr("Chọn ngôn ngữ") if not first_launch else "Chọn ngôn ngữ / Choose language"
	for code in _language_buttons:
		UiStyle.apply_button(_language_buttons[code], UiStyle.BRONZE_BRIGHT if code == Locales.current() and not first_launch else UiStyle.BRONZE)
	var today := Match.today()
	_title.text = tr("THÀNH TRÌ")
	_subtitle.text = tr("Hộ tống thành trì đi càng xa càng tốt")
	_play.text = tr("Chơi")
	_daily.text = tr("Thử thách hôm nay (%s)") % UiStyle.short_date(today)
	_coop.text = tr("Chơi cùng bạn bè")
	_records.text = tr("Kỷ lục: %s   ·   Hôm nay: %s   ·   Đã chơi %d trận") % [
		UiStyle.format_meters(SaveManager.best_distance()), UiStyle.format_meters(SaveManager.best_daily(today)),
		SaveManager.runs_played()]
	show()


## Shows how the room is doing. While `in_room` (connecting or connected) the room buttons are
## locked until leaving; `can_start` reveals the host's Start button.
func show_lobby_status(text: String, in_room: bool, can_start: bool = false) -> void:
	_lobby_status.text = text
	_start.visible = can_start
	_host.disabled = in_room
	_join.disabled = in_room
	_address.editable = not in_room


func _open_lobby() -> void:
	for control in [_subtitle, _play, _daily, _coop, _records, _language_title, _languages]:
		control.visible = false
	_lobby.visible = true
	_lobby_title.text = tr("Chơi cùng bạn bè")
	_host.text = tr("Tạo phòng")
	_address.placeholder_text = tr("Địa chỉ IP của chủ phòng")
	_join.text = tr("Vào phòng")
	_start.text = tr("Bắt đầu")
	_back.text = tr("Quay lại")
	_lobby_status.text = tr("Tối đa %d người. Cùng mạng LAN, hoặc mở cổng %d.") % [Net.MAX_PLAYERS, Net.PORT]
	_start.visible = false
	_host.disabled = false
	_join.disabled = false
	_address.editable = true


func _build_lobby() -> void:
	var column := _play.get_parent()
	_coop = Button.new()
	_coop.custom_minimum_size = Vector2(320, 50)
	_coop.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_coop.add_theme_font_size_override("font_size", 19)
	UiStyle.apply_button(_coop)
	_coop.pressed.connect(_open_lobby)
	column.add_child(_coop)
	column.move_child(_coop, _daily.get_index() + 1)

	_lobby = VBoxContainer.new()
	_lobby.add_theme_constant_override("separation", 14)
	_lobby.visible = false
	column.add_child(_lobby)
	column.move_child(_lobby, _records.get_index())
	_lobby_title = UiStyle.label("", 24, UiStyle.BRONZE_BRIGHT)
	_lobby_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lobby.add_child(_lobby_title)
	_host = _lobby_button(UiStyle.BRONZE_BRIGHT)
	_host.pressed.connect(host_requested.emit)
	_lobby.add_child(_host)

	var join_row := HBoxContainer.new()
	join_row.alignment = BoxContainer.ALIGNMENT_CENTER
	join_row.add_theme_constant_override("separation", 10)
	_address = LineEdit.new()
	_address.custom_minimum_size = Vector2(230, 48)
	_address.add_theme_font_size_override("font_size", 18)
	_address.add_theme_stylebox_override("normal", UiStyle.box(UiStyle.WOOD.darkened(0.3), UiStyle.BRONZE, 2, 8))
	_address.add_theme_stylebox_override("focus", UiStyle.box(UiStyle.WOOD.darkened(0.3), UiStyle.BRONZE_BRIGHT, 2, 8))
	_address.add_theme_color_override("font_color", UiStyle.PARCHMENT)
	_address.text_submitted.connect(func(_text: String) -> void: _request_join())
	join_row.add_child(_address)
	_join = _lobby_button(UiStyle.BRONZE)
	_join.custom_minimum_size = Vector2(130, 48)
	_join.pressed.connect(_request_join)
	join_row.add_child(_join)
	_lobby.add_child(join_row)

	_lobby_status = UiStyle.label("", 16, UiStyle.PARCHMENT)
	_lobby_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lobby_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lobby.add_child(_lobby_status)
	_start = _lobby_button(UiStyle.BRONZE_BRIGHT)
	_start.pressed.connect(online_start_requested.emit)
	_lobby.add_child(_start)
	_back = _lobby_button(UiStyle.MUTED)
	_back.pressed.connect(func() -> void:
		leave_requested.emit()
		open())
	_lobby.add_child(_back)


func _lobby_button(accent: Color) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(320, 48)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 19)
	UiStyle.apply_button(button, accent)
	return button


func _request_join() -> void:
	var address := _address.text.strip_edges()
	join_requested.emit(address if address != "" else "127.0.0.1")


func _on_language_picked(code: String) -> void:
	Locales.choose(code)
	open()  # redraw every text in the new language
