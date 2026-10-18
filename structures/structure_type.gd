class_name StructureType
extends Resource
## One buildable structure (turret, barricade, ...). Instances are spawned from `scene`.

@export var id: StringName
## Shown to players through tr().
@export var display_name: String
## Resources to build, keyed by ResourceType.id.
@export var cost: Dictionary = {}
@export var scene: PackedScene
## Foldable structures can be recovered, carried and placed again for free.
@export var foldable: bool = false
## Radius kept free of other obstacles when placing.
@export var footprint_radius: float = 1.0
## HUD/build menu icon. Optional: a coloured tile is drawn until art exists.
@export var icon: Texture2D
@export var color: Color = Color.WHITE
