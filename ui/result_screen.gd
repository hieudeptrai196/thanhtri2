class_name ResultScreen
extends Control
## End-of-run screen over a dimmed world. Reports the restart press; the match does the restart.

signal restart_requested
signal menu_requested

@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %Title
@onready var _stats: Label = %Stats
@onready var _restart: Button = %Restart
@onready var _menu: Button = %Menu
@onready var _record: Label = %Record


func _ready() -> void:
	_panel.add_theme_stylebox_override("panel", UiStyle.panel())
	UiStyle.outline(_title, 8)
	_stats.add_theme_color_override("font_color", UiStyle.PARCHMENT)
	UiStyle.apply_button(_restart, UiStyle.BRONZE_BRIGHT)
	_restart.text = tr("Chơi lại")
	_restart.pressed.connect(restart_requested.emit)
	UiStyle.apply_button(_menu)
	_menu.text = tr("Về menu")
	_menu.pressed.connect(menu_requested.emit)
	_record.add_theme_color_override("font_color", UiStyle.BRONZE_BRIGHT)
	UiStyle.outline(_record, 6)
	hide()


## `daily_date` is empty for a random run.
func show_result(distance: float, seconds: float, kills: int, best: float, is_record: bool, daily_date: String = "") -> void:
	_title.text = tr("Thành trì đã thất thủ")
	_title.add_theme_color_override("font_color", Color(0.9, 0.35, 0.3))
	_record.text = tr("Kỷ lục mới!") if is_record else ""
	_record.visible = is_record
	var heading := (tr("Thử thách ngày %s") % UiStyle.short_date(daily_date) + "\n") if daily_date != "" else ""
	_stats.text = heading + tr("Quãng đường: %s\nKỷ lục: %s\nThời gian: %d:%02d\nQuái đã hạ: %d") % [
		UiStyle.format_meters(distance), UiStyle.format_meters(best), int(seconds) / 60, int(seconds) % 60, kills]
	show()
