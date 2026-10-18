extends GameTest


func _match_at_stop(rng_seed: int = 1) -> Node:
	var m := await start_match(rng_seed)
	var follower: RouteFollower = m.get_node("Fortress/RouteFollower")
	follower.base_speed = 300.0
	for i in 300:
		await frames(1)
		if follower.is_stopped:
			break
	check(follower.is_stopped, "fortress reaches the stop")
	return m


func test_stop_offers_three_distinct_cards_deterministically() -> void:
	var m := await _match_at_stop(7)
	var first: Array = m.weapon_offers.map(func(u: WeaponUpgrade) -> StringName: return u.id)
	check(first.size() == 3, "three cards offered, got %d" % first.size())
	var unique := {}
	for id in first:
		unique[id] = true
	check(unique.size() == 3, "cards are distinct: %s" % [first])

	m = await _match_at_stop(7)
	var second: Array = m.weapon_offers.map(func(u: WeaponUpgrade) -> StringName: return u.id)
	check(first == second, "same seed gives the same offer: %s vs %s" % [first, second])


func test_buying_a_card_upgrades_weapon_once_per_stop() -> void:
	var m := await _match_at_stop()
	var weapon: MeleeWeapon = m.get_node("Warrior").weapon
	var storage: Inventory = m.get_node("Fortress").storage
	storage.add(&"bronze", 6)
	var before := {"damage": weapon.damage, "cooldown": weapon.cooldown, "arc": weapon.arc_degrees, "reach": weapon.get_reach()}
	var card: WeaponUpgrade = m.weapon_offers[0]

	check(m.request_weapon_upgrade(0), "buying the first card works")
	check(storage.get_amount(&"bronze") == 3, "card cost paid from fortress storage")
	check_near(weapon.damage, before.damage * card.damage_multiplier, 0.001, "damage")
	check_near(weapon.cooldown, before.cooldown * card.cooldown_multiplier, 0.001, "cooldown")
	check_near(weapon.arc_degrees, before.arc + card.arc_bonus_degrees, 0.001, "arc")
	check_near(weapon.get_reach(), before.reach * card.reach_multiplier, 0.001, "reach")
	check(not m.request_weapon_upgrade(1), "only one card per stop")
	check(storage.get_amount(&"bronze") == 3, "second attempt spends nothing")


func test_card_needs_bronze_and_a_stop() -> void:
	var m := await start_match()
	m.get_node("Fortress").storage.add(&"bronze", 10)
	check(not m.request_weapon_upgrade(0), "no cards while moving")

	m = await _match_at_stop()
	m.get_node("Fortress").storage.add(&"bronze", 2)
	check(not m.request_weapon_upgrade(0), "2 bronze is not enough")
	check(m.weapon_choice == -1, "still free to choose")


func test_each_card_effect_applies() -> void:
	for upgrade in WeaponUpgrades.ALL:
		var m := await start_match()
		var weapon: MeleeWeapon = m.get_node("Warrior").weapon
		var reach := weapon.get_reach()
		var damage := weapon.damage
		weapon.apply_upgrade(upgrade)
		var changed := weapon.get_reach() != reach or weapon.damage != damage \
			or weapon.cooldown != 0.5 or weapon.arc_degrees != 120.0
		check(changed, "card %s changes the weapon" % upgrade.id)


func test_reach_upgrade_does_not_leak_to_other_warriors() -> void:
	var m := await start_match()
	var weapon: MeleeWeapon = m.get_node("Warrior").weapon
	var other: Warrior = preload("res://player/warrior.tscn").instantiate()
	m.add_child(other)
	other.global_position = Vector3(60, 0.1, 60)
	await frames(1)
	weapon.apply_upgrade(preload("res://combat/upgrades/reach.tres"))
	check(other.weapon.get_reach() == 2.5, "other warrior keeps its reach, got %.2f" % other.weapon.get_reach())


func test_panel_cards_follow_bronze_and_choice() -> void:
	var m := await _match_at_stop()
	var panel: UpgradePanel = m.get_node("UI/UpgradePanel")
	check(panel._cards.size() == 3, "panel shows three cards")
	check(panel._cards.all(func(c: Button) -> bool: return c.disabled), "cards disabled without bronze")
	m.get_node("Fortress").storage.add(&"bronze", 3)
	check(panel._cards.all(func(c: Button) -> bool: return not c.disabled), "cards enabled with bronze")
	panel._cards[2].pressed.emit()
	check(m.weapon_choice == 2, "pressing a card buys it")
	check(panel._cards.all(func(c: Button) -> bool: return c.disabled), "all cards locked after choosing")


func test_card_shows_art_when_provided() -> void:
	var m := await _match_at_stop()
	var panel: UpgradePanel = m.get_node("UI/UpgradePanel")
	var card: WeaponCard = panel._cards[0]
	check(not card.get_node("%Art").visible and card.get_node("%ArtPlaceholder").visible,
		"placeholder shown while a card has no art")

	var with_art: WeaponUpgrade = m.weapon_offers[0].duplicate()
	with_art.art = ImageTexture.create_from_image(Image.create(64, 40, false, Image.FORMAT_RGB8))
	card.show_upgrade(with_art)
	check(card.get_node("%Art").visible and not card.get_node("%ArtPlaceholder").visible,
		"art replaces the placeholder")
	check(card.get_node("%Art").texture == with_art.art, "card uses the upgrade's art")
