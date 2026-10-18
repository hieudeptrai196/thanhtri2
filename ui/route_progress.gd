class_name RouteProgress
extends Control
## Strip from the previous stop to the next one, with the fortress as a moving dot and the
## metres left to the next stop.

var follower: RouteFollower


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if follower == null:
		return
	var from := follower.previous_stop_distance()
	var to := follower.next_stop_distance()
	var t := clampf((follower.distance - from) / maxf(to - from, 1.0), 0.0, 1.0)
	var y := size.y * 0.5
	var left := 12.0
	var right := size.x - 150.0
	var dot := Vector2(lerpf(left, right, t), y)

	draw_line(Vector2(left, y), Vector2(right, y), Color(0, 0, 0, 0.6), 8.0, true)
	draw_line(Vector2(left, y), Vector2(right, y), UiStyle.MUTED.darkened(0.2), 4.0, true)
	draw_line(Vector2(left, y), dot, UiStyle.BRONZE, 4.0, true)
	_draw_diamond(Vector2(left, y), UiStyle.MUTED)
	_draw_diamond(Vector2(right, y), UiStyle.BRONZE_BRIGHT)
	draw_circle(dot, 9.0, Color(0, 0, 0, 0.7))
	draw_circle(dot, 7.0, UiStyle.PARCHMENT)

	var text := tr("Điểm dừng: %d m") % maxi(ceili(to - follower.distance), 0)
	draw_string(ThemeDB.fallback_font, Vector2(right + 16.0, y + 6.0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiStyle.PARCHMENT)


func _draw_diamond(at: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(0, -8), at + Vector2(8, 0), at + Vector2(0, 8), at + Vector2(-8, 0)]), color)
