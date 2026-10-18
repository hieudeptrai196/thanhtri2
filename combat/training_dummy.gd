extends StaticBody3D
## Placeholder target for testing attacks. Shows its HP, flashes when hit, disappears at 0 HP.

@onready var _health: HealthComponent = $Health
@onready var _label: Label3D = $HealthLabel
@onready var _material: StandardMaterial3D = $Body.mesh.material

var _base_color: Color


func _ready() -> void:
	_base_color = _material.albedo_color
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(queue_free)
	_on_health_changed(_health.current, _health.max_health)


func _on_health_changed(current: float, maximum: float) -> void:
	_label.text = "%d / %d" % [current, maximum]
	_material.albedo_color = Color.WHITE
	create_tween().tween_property(_material, "albedo_color", _base_color, 0.15)
