class_name RouteProgress
extends Control
## Route strip: start → stops (diamonds) → end flag, with the fortress as a moving dot.

var follower: RouteFollower


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if follower == null or follower.get_length() <= 0.0:
		return
	var length := follower.get_length()
	var y := size.y * 0.5
	var left := 12.0
	var right := size.x - 12.0
	var at := func(offset: float) -> Vector2: return Vector2(lerpf(left, right, offset / length), y)

	draw_line(Vector2(left, y), Vector2(right, y), Color(0, 0, 0, 0.6), 8.0, true)
	draw_line(Vector2(left, y), Vector2(right, y), UiStyle.MUTED.darkened(0.2), 4.0, true)
	draw_line(Vector2(left, y), at.call(follower.progress), UiStyle.BRONZE, 4.0, true)
	for offset in follower.get_stop_offsets():
		var p: Vector2 = at.call(offset)
		var diamond := PackedVector2Array([p + Vector2(0, -8), p + Vector2(8, 0), p + Vector2(0, 8), p + Vector2(-8, 0)])
		draw_colored_polygon(diamond, UiStyle.BRONZE_BRIGHT if offset > follower.progress else UiStyle.MUTED)
	draw_rect(Rect2(Vector2(right - 2, y - 11), Vector2(4, 22)), UiStyle.PARCHMENT)
	draw_rect(Rect2(Vector2(right + 2, y - 11), Vector2(10, 7)), Color(0.8, 0.2, 0.15))
	var dot: Vector2 = at.call(follower.progress)
	draw_circle(dot, 9.0, Color(0, 0, 0, 0.7))
	draw_circle(dot, 7.0, UiStyle.PARCHMENT)
