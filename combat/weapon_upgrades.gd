class_name WeaponUpgrades
## Pool of weapon upgrade cards offered at stops.

const ALL: Array[WeaponUpgrade] = [
	preload("res://combat/upgrades/damage.tres"),
	preload("res://combat/upgrades/speed.tres"),
	preload("res://combat/upgrades/arc.tres"),
	preload("res://combat/upgrades/reach.tres"),
]


## `count` distinct cards drawn with the given RNG (the match's seeded one).
static func draw(rng: RandomNumberGenerator, count: int) -> Array[WeaponUpgrade]:
	var pool := ALL.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: WeaponUpgrade = pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	return pool.slice(0, mini(count, pool.size()))
