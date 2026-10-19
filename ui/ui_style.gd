class_name UiStyle
## Shared look for in-game UI: heavy riveted iron frames over dark stone, tarnished gold, blood red
## and bone-coloured text, gothic titles. Frames are drawn in code (no art files needed); dropping
## a 9-slice image at CARD_FRAME_PATH still replaces the card frame. The constant names are the
## original wood/bronze ones, kept so every screen picks up the new palette.

const WOOD_DARK := Color(0.055, 0.05, 0.055, 0.95)  # near-black iron
const WOOD := Color(0.11, 0.1, 0.1, 1.0)  # dark iron
const WOOD_LIGHT := Color(0.19, 0.17, 0.16, 1.0)  # worn iron (hover)
const BRONZE := Color(0.7, 0.53, 0.28, 1.0)  # tarnished gold
const BRONZE_BRIGHT := Color(0.96, 0.76, 0.4, 1.0)
const PARCHMENT := Color(0.88, 0.84, 0.76, 1.0)  # bone
const MUTED := Color(0.5, 0.46, 0.42, 1.0)
const BLOOD := Color(0.62, 0.09, 0.07, 1.0)
const TITLE_FONT := "res://assets/fonts/grenze/GrenzeGotisch.ttf"
## Labels this big or bigger use the gothic title face.
const TITLE_SIZE := 26
## Unstretched border of the drawn iron frame, in pixels.
const IRON_SLICE := 22

## Drop a 9-slice frame image here to replace the drawn card frame; the outer CARD_FRAME_SLICE
## pixels on each side stay unstretched.
const CARD_FRAME_PATH := "res://ui/art/card_frame.png"
const CARD_FRAME_SLICE := 24

static var _frames: Dictionary = {}
static var _title_font: Font


## A riveted iron frame over dark stone, tinted by `border` (trim) and `background` (fill).
## `border_width` > 2 draws the heavier, highlighted variant (hover, selected).
static func box(background: Color, border: Color, border_width: int = 2, _radius: int = 10) -> StyleBox:
	var style := StyleBoxTexture.new()
	style.texture = _iron_frame(background, border, border_width > 2)
	style.set_texture_margin_all(IRON_SLICE)
	style.set_content_margin_all(16.0)
	return style


static func panel() -> StyleBox:
	return box(WOOD_DARK, BRONZE, 2)


## The gothic face used for titles.
static func title_font() -> Font:
	if _title_font == null:
		var variation := FontVariation.new()
		variation.base_font = load(TITLE_FONT)
		variation.variation_opentype = {"wght": 600}
		_title_font = variation
	return _title_font


## Iron button with gold trim; brighter on hover, dim when disabled.
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


## Card frame: the art file at CARD_FRAME_PATH if present, otherwise a drawn iron frame.
static func card_frame(border: Color, border_width: int = 2, tint: Color = Color.WHITE, background: Color = WOOD) -> StyleBox:
	if ResourceLoader.exists(CARD_FRAME_PATH):
		var style := StyleBoxTexture.new()
		style.texture = load(CARD_FRAME_PATH)
		style.set_texture_margin_all(CARD_FRAME_SLICE)
		style.set_content_margin_all(CARD_FRAME_SLICE)
		style.modulate_color = tint
		return style
	var framed := box(background, border, border_width) as StyleBoxTexture
	framed.modulate_color = tint
	return framed


static func apply_card(card: Button) -> void:
	card.focus_mode = Control.FOCUS_NONE
	card.add_theme_stylebox_override("normal", card_frame(BRONZE.darkened(0.25)))
	card.add_theme_stylebox_override("hover", card_frame(BRONZE_BRIGHT, 3, Color(1, 0.95, 0.85), WOOD_LIGHT))
	card.add_theme_stylebox_override("pressed", card_frame(BRONZE_BRIGHT, 3, Color(0.85, 0.85, 0.85), WOOD_DARK))
	card.add_theme_stylebox_override("disabled", card_frame(MUTED.darkened(0.3), 2, Color(0.6, 0.6, 0.6)))


## Lighter, semi-transparent panel for the always-on HUD.
static func hud_panel() -> StyleBox:
	var style := box(Color(WOOD_DARK, 0.82), BRONZE.darkened(0.2), 2)
	style.set_content_margin_all(12.0)
	return style


## Styles a ProgressBar as a sunken iron channel with a beveled fill of the given colour.
static func apply_bar(bar: ProgressBar, fill: Color) -> void:
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.02, 0.02, 0.02, 0.85)
	background.border_color = Color(0.3, 0.28, 0.26)
	background.set_border_width_all(2)
	background.set_corner_radius_all(2)
	var foreground := StyleBoxFlat.new()
	foreground.bg_color = fill.darkened(0.15)
	foreground.border_color = fill.lightened(0.3)
	foreground.border_width_top = 2
	foreground.set_corner_radius_all(1)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", foreground)


## Gives every big label under `root` (font size >= TITLE_SIZE) the gothic title face.
static func gothic_titles(root: Node) -> void:
	for node in root.find_children("*", "Label", true, false):
		var label_node := node as Label
		if label_node.has_theme_font_size_override("font_size") and label_node.get_theme_font_size("font_size") >= TITLE_SIZE:
			label_node.add_theme_font_override("font", title_font())


## Text readable over the 3D world.
static func outline(target: Label, size: int = 6) -> void:
	target.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
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
	if size >= TITLE_SIZE:
		result.add_theme_font_override("font", title_font())
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


# Drawn once per colour combination: a black rim, a steel band lit from the top-left, a thin gold
# line inside, brass rivets at the corners and stone-like grain in the fill. 9-sliced by box().
static func _iron_frame(background: Color, trim: Color, heavy: bool) -> ImageTexture:
	var key := [background, trim, heavy]
	if _frames.has(key):
		return _frames[key]
	var size := 96
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.frequency = 0.09
	noise.seed = 7
	var steel := Color(0.24, 0.23, 0.23).lerp(trim, 0.18)
	for y in size:
		for x in size:
			var edge := mini(mini(x, y), mini(size - 1 - x, size - 1 - y))
			var grain := noise.get_noise_2d(x, y) * 0.5 + 0.5
			var color: Color
			if edge < 2:
				color = Color(0.02, 0.02, 0.02, 1.0)
			elif edge < 7:
				var lit := 1.15 if x + y < size else 0.8
				color = (steel * lit).lerp(steel.darkened(0.35), grain * 0.4)
				color.a = 1.0
			elif edge < (10 if heavy else 9):
				color = trim if heavy else trim.darkened(0.35)
			else:
				color = background.lerp(background.lightened(0.1), grain * 0.6)
				color.a = background.a
			image.set_pixel(x, y, color)
	for corner in [Vector2i(5, 5), Vector2i(size - 6, 5), Vector2i(5, size - 6), Vector2i(size - 6, size - 6)]:
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				var d := sqrt(dx * dx + dy * dy)
				if d <= 3.0:
					var shine := 1.25 - (dx + dy + 6) / 12.0 * 0.6
					image.set_pixel(corner.x + dx, corner.y + dy,
						Color(trim.lightened(0.1) * shine, 1.0) if d < 2.3 else Color(0.05, 0.04, 0.03))
	var texture := ImageTexture.create_from_image(image)
	_frames[key] = texture
	return texture
