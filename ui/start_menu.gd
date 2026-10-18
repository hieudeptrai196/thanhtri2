class_name StartMenu
extends Control
## Start screen: play a random road or today's daily challenge, with local records, and the
## language picker (shown alone on the very first launch).
## Only reports the choice; the match starts the run.

signal play_requested
signal daily_requested

@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _play: Button = %Play
@onready var _daily: Button = %Daily
@onready var _records: Label = %Records
@onready var _language_title: Label = %LanguageTitle
@onready var _languages: HBoxContainer = %Languages

var _language_buttons: Dictionary = {}


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
	for control in [_subtitle, _play, _daily, _records]:
		control.visible = not first_launch
	_language_title.text = tr("Chọn ngôn ngữ") if not first_launch else "Chọn ngôn ngữ / Choose language"
	for code in _language_buttons:
		UiStyle.apply_button(_language_buttons[code], UiStyle.BRONZE_BRIGHT if code == Locales.current() and not first_launch else UiStyle.BRONZE)
	var today := Match.today()
	_title.text = tr("THÀNH TRÌ")
	_subtitle.text = tr("Hộ tống thành trì đi càng xa càng tốt")
	_play.text = tr("Chơi")
	_daily.text = tr("Thử thách hôm nay (%s)") % UiStyle.short_date(today)
	_records.text = tr("Kỷ lục: %s   ·   Hôm nay: %s   ·   Đã chơi %d trận") % [
		UiStyle.format_meters(SaveManager.best_distance()), UiStyle.format_meters(SaveManager.best_daily(today)),
		SaveManager.runs_played()]
	show()


func _on_language_picked(code: String) -> void:
	Locales.choose(code)
	open()  # redraw every text in the new language
