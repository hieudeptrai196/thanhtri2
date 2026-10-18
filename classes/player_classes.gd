class_name PlayerClasses
## Every playable class, in picker order.

const ALL: Array[PlayerClass] = [
	preload("res://classes/types/engineer.tres"),
	preload("res://classes/types/woodcutter.tres"),
	preload("res://classes/types/general.tres"),
	preload("res://classes/types/shaman.tres"),
	preload("res://classes/types/mechanic.tres"),
]


## The class this player last picked on the menu (null = none picked yet).
static func chosen() -> PlayerClass:
	return find(StringName(SaveManager.get_setting("class", "")))


static func choose(player_class: PlayerClass) -> void:
	SaveManager.set_setting("class", String(player_class.id) if player_class else "")


static func find(id: StringName) -> PlayerClass:
	for player_class in ALL:
		if player_class.id == id:
			return player_class
	return null
