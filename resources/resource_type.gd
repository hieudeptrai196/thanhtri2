class_name ResourceType
extends Resource
## One kind of gatherable resource. Inventories store amounts by `id`.

@export var id: StringName
## Shown to players through tr(), so it doubles as the translation key.
@export var display_name: String
@export var color: Color = Color.WHITE
## HUD icon. Optional: a coloured tile is drawn until art exists.
@export var icon: Texture2D
