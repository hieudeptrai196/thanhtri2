class_name Structure
extends StaticBody3D
## A building placed in the field. While near the fortress it is supplied; away from it, a structure
## that needs power runs on its buffer until that runs out. Damage goes through its HealthComponent.

signal destroyed(structure: Structure)

## Set by the StructureNetwork when spawned.
var type: StructureType

@export var needs_power: bool = true
## Seconds of operation away from the fortress.
@export var buffer_seconds: float = 30.0
## Enemies within this distance turn to attack the structure.
@export var lure_radius: float = 6.0

@onready var health: HealthComponent = $Health

var buffer: float
var powered: bool = false


func _ready() -> void:
	add_to_group(&"structures")
	buffer = buffer_seconds
	health.died.connect(_on_died)


## Called every physics tick by the network. `in_range` = within the fortress service radius.
func supply(delta: float, in_range: bool) -> void:
	powered = in_range
	if not needs_power:
		return
	if in_range:
		buffer = buffer_seconds
	elif buffer > 0.0:
		buffer = maxf(buffer - delta, 0.0)
		if buffer == 0.0:
			_on_buffer_empty()


func is_running() -> bool:
	return not needs_power or buffer > 0.0


## Foldable structures can normally be recovered; subclasses may refuse (e.g. while overloading).
func can_recover() -> bool:
	return type != null and type.foldable


func _on_buffer_empty() -> void:
	pass


func _on_died() -> void:
	destroyed.emit(self)
	queue_free()
