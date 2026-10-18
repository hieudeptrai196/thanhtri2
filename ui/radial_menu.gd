class_name RadialMenu
extends Control
## Gamepad build menu: entries around a circle, the one under the right stick highlighted.
## Shown while the player's Builder has the radial open; the Builder does the selecting.

const RADIUS := 110.0
const ENTRY_RADIUS := 46.0

var _builder: Builder


func setup(builder: Builder) -> void:
	_builder = builder


func _process(_delta: float) -> void:
	visible = _builder != null and _builder.radial_open
	if visible:
		queue_redraw()


func _draw() -> void:
	var centre := size * 0.5
	var count := StructureTypes.ALL.size()
	draw_circle(centre, RADIUS + ENTRY_RADIUS + 10.0, Color(UiStyle.WOOD_DARK, 0.6))
	for i in count:
		var type := StructureTypes.ALL[i]
		var angle := TAU * i / count - PI * 0.5  # first entry at the top, clockwise
		var at := centre + Vector2(cos(angle), sin(angle)) * RADIUS
		var highlighted := _builder.radial_highlight == i
		draw_circle(at, ENTRY_RADIUS, UiStyle.WOOD_LIGHT if highlighted else UiStyle.WOOD)
		draw_arc(at, ENTRY_RADIUS, 0.0, TAU, 32, UiStyle.BRONZE_BRIGHT if highlighted else UiStyle.BRONZE, 3.0, true)
		draw_circle(at + Vector2(0, -12), 10.0, type.color)
		var label_text := tr(type.display_name)
		var width := ThemeDB.fallback_font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		draw_string(ThemeDB.fallback_font, at + Vector2(-width * 0.5, 16), label_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UiStyle.PARCHMENT)
