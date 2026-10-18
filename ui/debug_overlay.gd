class_name DebugOverlay
extends Label
## Developer performance readout, toggled with F3. Not player-facing, so text is not translated.

const TOGGLE_KEY := KEY_F3


func _ready() -> void:
	visible = false
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	UiStyle.outline(self, 4)


# Dev tool, so it reads the key directly instead of going through PlayerInput.
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == TOGGLE_KEY:
		visible = not visible


func _process(_delta: float) -> void:
	if not visible:
		return
	text = "FPS %d   frame %.1f ms\nprocess %.2f ms   physics %.2f ms\nenemies %d   nodes %d   draw calls %d" % [
		Engine.get_frames_per_second(),
		1000.0 / maxf(Engine.get_frames_per_second(), 1.0),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		get_tree().get_node_count_in_group(&"enemies"),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
	]
