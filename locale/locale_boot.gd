extends Node
## Autoload: applies the saved language before the first scene builds any text.
## Also turns on physics interpolation before any scene exists (physics runs at 60 Hz, screens
## refresh faster); switching it on once nodes are in the tree left the sun lighting sideways.


func _init() -> void:
	Locales.apply_saved()


func _enter_tree() -> void:
	get_tree().physics_interpolation = true
	_apply_font()


# Be Vietnam Pro (OFL, full Vietnamese) for every Control, bold as the theme's bold face. Set on the
# root window's theme so it needs no project setting.
func _apply_font() -> void:
	var regular: FontFile = load("res://assets/fonts/BeVietnamPro-Regular.ttf")
	var bold: FontFile = load("res://assets/fonts/BeVietnamPro-Bold.ttf")
	var font := FontVariation.new()
	font.base_font = bold if bold else regular
	var theme := Theme.new()
	theme.default_font = font
	get_tree().root.theme = theme
