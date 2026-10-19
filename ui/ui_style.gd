class_name UiStyle
## Shared placeholder look for in-game UI (dark wood + bronze) until the real art direction exists.
## Keeps UI away from default form widgets; swap these values when the final theme is designed.

const WOOD_DARK := Color(0.13, 0.09, 0.06, 0.94)
const WOOD := Color(0.24, 0.16, 0.10, 1.0)
const WOOD_LIGHT := Color(0.33, 0.23, 0.14, 1.0)
const BRONZE := Color(0.86, 0.6, 0.26, 1.0)
const BRONZE_BRIGHT := Color(1.0, 0.8, 0.42, 1.0)
const PARCHMENT := Color(0.96, 0.91, 0.8, 1.0)
const MUTED := Color(0.55, 0.5, 0.44, 1.0)

## Drop a 9-slice frame image here to replace the drawn card frame; the outer CARD_FRAME_SLICE
## pixels on each side stay unstretched.
const CARD_FRAME_PATH := "res://ui/art/card_frame.png"
const CARD_FRAME_SLICE := 24


static func box(background: Color, border: Color, border_width: int = 2, radius: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(14.0)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 6
	return style


static func panel() -> StyleBoxFlat:
	return box(WOOD_DARK, BRONZE, 3, 14)


## Wood button with bronze border; brighter on hover, dim when disabled.
static func apply_button(button: Button, accent: Color = BRONZE) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: Sfx.play_ui(button, &"click"))
	button.add_theme_stylebox_override("normal", box(WOOD, accent.darkened(0.25)))
	button.add_theme_stylebox_override("hover", box(WOOD_LIGHT, BRONZE_BRIGHT, 3))
	button.add_theme_stylebox_override("pressed", box(WOOD_DARK, BRONZE_BRIGHT, 3))
	button.add_theme_stylebox_override("disabled", box(Color(WOOD, 0.6), MUTED.darkened(0.3)))
	button.add_theme_color_override("font_color", PARCHMENT)
	button.add_theme_color_override("font_hover_color", BRONZE_BRIGHT)
	button.add_theme_color_override("font_disabled_color", MUTED)


## Card frame: the art file at CARD_FRAME_PATH if present, otherwise a drawn wood/bronze box.
static func card_frame(border: Color, border_width: int = 2, tint: Color = Color.WHITE, background: Color = WOOD) -> StyleBox:
	if ResourceLoader.exists(CARD_FRAME_PATH):
		var style := StyleBoxTexture.new()
		style.texture = load(CARD_FRAME_PATH)
		style.set_texture_margin_all(CARD_FRAME_SLICE)
		style.set_content_margin_all(CARD_FRAME_SLICE)
		style.modulate_color = tint
		return style
	return box(background, border, border_width)


static func apply_card(card: Button) -> void:
	card.focus_mode = Control.FOCUS_NONE
	card.add_theme_stylebox_override("normal", card_frame(BRONZE.darkened(0.25)))
	card.add_theme_stylebox_override("hover", card_frame(BRONZE_BRIGHT, 3, Color(1, 0.95, 0.8), WOOD_LIGHT))
	card.add_theme_stylebox_override("pressed", card_frame(BRONZE_BRIGHT, 3, Color(0.85, 0.85, 0.85), WOOD_DARK))
	card.add_theme_stylebox_override("disabled", card_frame(MUTED.darkened(0.3), 2, Color(0.6, 0.6, 0.6)))


## Lighter, semi-transparent panel for the always-on HUD.
static func hud_panel() -> StyleBoxFlat:
	var style := box(Color(WOOD_DARK, 0.78), BRONZE.darkened(0.3), 2, 10)
	style.set_content_margin_all(10.0)
	return style


## Styles a ProgressBar as a rounded bar with the given fill colour.
static func apply_bar(bar: ProgressBar, fill: Color) -> void:
	bar.show_percentage = false
	var background := box(Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.8), 1, 5)
	background.set_content_margin_all(0.0)
	background.shadow_size = 0
	var foreground := box(fill, fill.lightened(0.25), 1, 5)
	foreground.set_content_margin_all(0.0)
	foreground.shadow_size = 0
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", foreground)


## Text readable over the 3D world.
static func outline(target: Label, size: int = 6) -> void:
	target.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	target.add_theme_constant_override("outline_size", size)


## Whole metres with thousands grouping, e.g. 12345 -> "12.345 m".
static func format_meters(distance: float) -> String:
	var digits := str(floori(distance))
	var grouped := ""
	while digits.length() > 3:
		grouped = "." + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return digits + grouped + " m"


## "YYYY-MM-DD" -> "DD/MM".
static func short_date(date: String) -> String:
	var parts := date.split("-")
	return "%s/%s" % [parts[2], parts[1]] if parts.size() == 3 else date


static func label(text: String, size: int, color: Color = PARCHMENT) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result
