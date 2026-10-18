class_name FortressTier
extends Resource
## One material level of the fortress body (wood, stone, ...).

@export var id: StringName
## Shown to players through tr().
@export var display_name: String
@export var max_health: float = 500.0
@export var color: Color = Color.WHITE
## Resources needed to reach this tier, keyed by ResourceType.id. Empty for the starting tier.
@export var cost: Dictionary = {}
