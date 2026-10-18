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


## "Đá 10, Gỗ 5" style text for a cost/contents dictionary, in display order.
static func format_amounts(amounts: Dictionary) -> String:
	var parts: PackedStringArray = []
	for type in ALL:
		if amounts.get(type.id, 0) > 0:
			parts.append("%s %d" % [TranslationServer.translate(type.display_name), amounts[type.id]])
	return ", ".join(parts)
