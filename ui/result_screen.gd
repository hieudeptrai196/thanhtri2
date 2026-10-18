class_name ResultScreen
extends Control
## End-of-run screen over a dimmed world. Reports the restart press; the match does the restart.

signal restart_requested

@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %Title
@onready var _stats: Label = %Stats
@onready var _restart: Button = %Restart


func _ready() -> void:
	_panel.add_theme_stylebox_override("panel", UiStyle.panel())
	UiStyle.outline(_title, 8)
	_stats.add_theme_color_override("font_color", UiStyle.PARCHMENT)
	UiStyle.apply_button(_restart, UiStyle.BRONZE_BRIGHT)
	_restart.text = tr("Chơi lại")
	_restart.pressed.connect(restart_requested.emit)
	hide()


func show_result(won: bool, seconds: float, kills: int, fortress_health: float, fortress_max: float) -> void:
	_title.text = tr("Thành trì đã tới đích!") if won else tr("Thành trì đã thất thủ")
	_title.add_theme_color_override("font_color", UiStyle.BRONZE_BRIGHT if won else Color(0.9, 0.35, 0.3))
	_stats.text = tr("Thời gian: %d:%02d\nQuái đã hạ: %d\nMáu pháo đài: %d/%d") % [
		int(seconds) / 60, int(seconds) % 60, kills, fortress_health, fortress_max]
	show()
