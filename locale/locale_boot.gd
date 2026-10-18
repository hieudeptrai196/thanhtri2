extends Node
## Autoload: applies the saved language before the first scene builds any text.


func _init() -> void:
	Locales.apply_saved()
