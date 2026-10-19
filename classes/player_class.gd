class_name PlayerClass
extends Resource
## A class = a co-op role. Passive strengths are plain multipliers applied to the warrior (or, for
## team-wide ones, to the fortress while someone of this class plays). The active skill is chosen by
## `id` in ClassSkills and tuned by the Skill numbers.
## Numbers are proposals to be tuned in playtests.

@export var id: StringName
## Shown to players through tr().
@export var display_name: String
## What the class is good at (the passive), one or two short sentences.
@export_multiline var description: String
@export var skill_name: String
@export_multiline var skill_description: String
@export_group("Skill")
## Seconds between uses.
@export var skill_cooldown: float = 15.0
## Seconds the effect lasts (0 = instant).
@export var skill_duration: float = 0.0
## Reach / radius of the effect in metres.
@export var skill_radius: float = 8.0
## Strength: build speed ×, units per strike, damage taken ×, heal per second… depends on the skill.
@export var skill_power: float = 1.0
@export_group("")

## Placeholder body tint until there are class models.
@export var color: Color = Color(0.2, 0.45, 0.9)
## Later: portrait for the picker card.
@export var art: Texture2D

@export_group("Warrior")
@export var max_health_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
## Counts as this many hammers on a blueprint.
@export var hammer_multiplier: float = 1.0
## Repairs the fortress this many times as fast.
@export var repair_multiplier: float = 1.0
## Folded structures carried at once.
@export var carry_capacity: int = 1
@export var capacity_multiplier: float = 1.0
## Move speed multiplier with an empty pack and nothing on the back.
@export var empty_speed_multiplier: float = 1.0

@export_group("Around them")
## Structures within this radius fire faster (0 = no aura).
@export var structure_aura_radius: float = 0.0
@export var structure_fire_rate: float = 1.0

@export_group("Combos with other classes")
## Teammates hammering a blueprint within this distance pay from this class's bag before the storage (Tiều phu).
@export var bag_share_radius: float = 0.0
## When this class hammers, each unit from a teammate's shared bag counts this much (Công binh).
@export var shared_bag_value: float = 1.0
## Turrets this class finishes inside a structure aura (Thầy pháp) fire this much faster for good (Công binh).
@export var engrave_fire_rate: float = 1.0
## Crossbow range multiplier while this class mans it during Đốt lò (Thợ máy).
@export var stoked_gunner_range: float = 1.0

@export_group("Team (while this class plays)")
@export var overdrive_fuel_multiplier: float = 1.0
@export var upgrade_cost_multiplier: float = 1.0
