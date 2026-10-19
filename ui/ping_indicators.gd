class_name PingIndicators
extends Control
## Arrows at the screen edge pointing at teammates' pings that are off screen, in their colours.
## Pings on screen need nothing here: their mark in the world says what they mean.

## Distance of an arrow from the screen edge, in pixels.
const MARGIN := 36.0
const ARROW_SIZE := 18.0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	for marker: PingMarker in get_tree().get_nodes_in_group(&"pings"):
		if marker.is_queued_for_deletion() or marker.get_world_3d() != camera.get_world_3d():
			continue
		var at := marker.global_position + Vector3(0.0, 1.5, 0.0)
		var edge: Variant = edge_point(camera.unproject_position(at), camera.is_position_behind(at), Rect2(Vector2.ZERO, size), MARGIN)
		if edge != null:
			_draw_arrow(edge, (edge as Vector2 - size * 0.5).normalized(), marker.color)


## Where to put an arrow for a point projected to `screen` (null when it is on screen): clamped onto a
## rectangle `margin` inside `rect`, along the line from the centre. Points behind the camera flip.
static func edge_point(screen: Vector2, behind: bool, rect: Rect2, margin: float) -> Variant:
	var inner := rect.grow(-margin)
	if not behind and inner.has_point(screen):
		return null
	var centre := rect.get_center()
	var direction := screen - centre
	if behind:
		direction = -direction
	if direction.length() < 0.001:
		direction = Vector2.DOWN
	var half := inner.size * 0.5
	var scale_to_edge := minf(half.x / maxf(absf(direction.x), 0.001), half.y / maxf(absf(direction.y), 0.001))
	return centre + direction * scale_to_edge


func _draw_arrow(at: Vector2, direction: Vector2, color: Color) -> void:
	var side := direction.orthogonal()
	var tip := at + direction * ARROW_SIZE
	var points := PackedVector2Array([tip, at + side * ARROW_SIZE * 0.7, at - side * ARROW_SIZE * 0.7])
	draw_circle(at, ARROW_SIZE * 0.75, Color(UiStyle.WOOD_DARK, 0.75))
	draw_colored_polygon(points, color.lightened(0.2))
	draw_circle(at, ARROW_SIZE * 0.35, color)
