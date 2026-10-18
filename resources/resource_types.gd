class_name ResourceTypes
## Every resource type in the game, in display order.

const ALL: Array[ResourceType] = [
	preload("res://resources/types/wood.tres"),
	preload("res://resources/types/stone.tres"),
	preload("res://resources/types/bronze.tres"),
]


static func find(id: StringName) -> ResourceType:
	for type in ALL:
		if type.id == id:
			return type
	return null
