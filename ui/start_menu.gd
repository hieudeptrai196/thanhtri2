class_name StartMenu
extends Control
## Start screen: play a random road or today's daily challenge, with local records.
## Only reports the choice; the match starts the run.

signal play_requested
signal daily_requested

@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _play: Button = %Play
@onready var _daily: Button = %Daily
@onready var _records: Label = %Records


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
	hide()


func open() -> void:
	var today := Match.today()
	_title.text = tr("THÀNH TRÌ")
	_subtitle.text = tr("Hộ tống thành trì đi càng xa càng tốt")
	_play.text = tr("Chơi")
	_daily.text = tr("Thử thách hôm nay (%s)") % UiStyle.short_date(today)
	_records.text = tr("Kỷ lục: %s   ·   Hôm nay: %s   ·   Đã chơi %d trận") % [
		UiStyle.format_meters(SaveManager.best_distance()), UiStyle.format_meters(SaveManager.best_daily(today)),
		SaveManager.runs_played()]
	show()
