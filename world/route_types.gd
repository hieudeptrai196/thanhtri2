class_name RouteTypes
## Road stretches that stops can offer.

const ALL: Array[RouteType] = [
	preload("res://world/routes/old_forest.tres"),
	preload("res://world/routes/coal_mine.tres"),
	preload("res://world/routes/plains.tres"),
	preload("res://world/routes/ruined_temple.tres"),
]


## `count` distinct route types drawn with the given RNG (seeded by the run).
static func draw(rng: RandomNumberGenerator, count: int) -> Array[RouteType]:
	var pool := ALL.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: RouteType = pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	return pool.slice(0, mini(count, pool.size()))
