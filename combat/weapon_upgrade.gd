class_name WeaponUpgrade
extends Resource
## One weapon upgrade card offered at stops. Effects stack when bought again later.

@export var id: StringName
## Shown to players through tr().
@export var display_name: String
@export_multiline var description: String
## Card illustration. Optional: the card shows a placeholder until art exists.
@export var art: Texture2D
## Resources to buy, keyed by ResourceType.id.
@export var cost: Dictionary = {&"bronze": 3}

@export var damage_multiplier: float = 1.0
## Below 1 attacks faster.
@export var cooldown_multiplier: float = 1.0
@export var arc_bonus_degrees: float = 0.0
@export var reach_multiplier: float = 1.0
