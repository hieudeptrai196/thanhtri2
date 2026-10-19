extends Node
## Autoload: applies the saved language before the first scene builds any text.
## Also turns on physics interpolation before any scene exists (physics runs at 60 Hz, screens
## refresh faster); switching it on once nodes are in the tree left the sun lighting sideways.


func _init() -> void:
	Locales.apply_saved()


func _enter_tree() -> void:
	get_tree().physics_interpolation = true
	_apply_font()


# Grenze (OFL, full Vietnamese) at a semi-bold weight for every Control; titles switch to its gothic
# sister face (UiStyle.gothic_titles). Set as the global fallback font so it needs no project setting.
func _apply_font() -> void:
	var font := FontVariation.new()
	font.base_font = load("res://assets/fonts/grenze/Grenze.ttf")
	font.variation_opentype = {"wght": 560}
	# The engine's default theme reaches every Control, including those under CanvasLayers (a theme
	# on the root window does not); the fallback covers custom-drawn text.
	ThemeDB.get_default_theme().default_font = font
	ThemeDB.fallback_font = font
