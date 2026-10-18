class_name RouteType
extends Resource
## A kind of road stretch offered at stops. Applies from the stop where it is picked to the next one:
## how rich the roadside is, how dangerous it is, and how it looks.

@export var id: StringName
## Shown to players through tr().
@export var display_name: String
@export_multiline var description: String
@export var tree_multiplier: float = 1.0
@export var coal_multiplier: float = 1.0
@export var bomb_multiplier: float = 1.0
@export var enemy_rate_multiplier: float = 1.0
@export var enemy_health_multiplier: float = 1.0
## Multiplies what enemies drop (bronze).
@export var drop_multiplier: float = 1.0
@export var ground_color_a: Color = Color(0.32, 0.45, 0.25)
@export var ground_color_b: Color = Color(0.28, 0.40, 0.22)
## Card illustration. Optional: the card shows a placeholder until art exists.
@export var art: Texture2D
