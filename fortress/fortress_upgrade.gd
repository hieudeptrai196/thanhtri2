class_name FortressUpgrade
extends Resource
## One fortress upgrade track (crossbow, boiling oil, furnace, shield...). Bought level by level at
## stops with mixed gathered resources; what each level does is applied by Fortress by `id`.

@export var id: StringName
## Shown to players through tr().
@export var display_name: String
@export_multiline var description: String
## Cost of each level in order (level 1 = costs[0]), keyed by ResourceType.id.
@export var costs: Array[Dictionary] = []


func max_level() -> int:
	return costs.size()
