class_name WeaponWheel
extends Node2D
## Weapon wheel drawn around the hero (GDD "Roda de armas"): LB held slows
## time, the stick highlights a weapon, X/Y equip it to slot I/II.
## Dot under a weapon = where it is equipped (blue X = slot I, yellow Y = II,
## the Xbox face colours).

const ATLAS := preload("res://assets/kenney/tiny_dungeon/tilemap_packed.png")
const RADIUS := 26.0
const SLOT_COLORS := [Color(0.35, 0.6, 1.0), Color(1.0, 0.85, 0.3)]

var _hero: Hero
var _open := false
var _highlight := -1


func _ready() -> void:
	_hero = get_parent() as Hero
	z_index = 20
	visible = false
	if _hero:
		_hero.wheel_changed.connect(_on_wheel_changed)
		_hero.weapons_changed.connect(func(_a: WeaponData, _b: WeaponData) -> void: queue_redraw())


## Slots are laid out clockwise from the top; returns the one nearest
## [param direction].
static func slot_for_direction(direction: Vector2, count: int) -> int:
	if count <= 0 or direction.is_zero_approx():
		return -1
	var best := 0
	var best_gap := INF
	for i in count:
		var gap := absf(angle_difference(direction.angle(), slot_angle(i, count)))
		if gap < best_gap:
			best_gap = gap
			best = i
	return best


static func slot_angle(index: int, count: int) -> float:
	return -PI / 2.0 + TAU * index / float(count)


## New [slot I, slot II] after putting [param weapon] in [param slot]. If the
## weapon was in the other slot, the two swap, so a weapon is never in both.
static func equip(slots: Array, slot: int, weapon: WeaponData) -> Array:
	var result := slots.duplicate()
	var other := 1 - slot
	if result[other] == weapon:
		result[other] = result[slot]
	result[slot] = weapon
	return result


func _on_wheel_changed(open: bool, highlighted: int) -> void:
	_open = open
	_highlight = highlighted
	visible = open
	queue_redraw()


func _draw() -> void:
	if not _open or _hero == null:
		return
	var center := Vector2(0, -8)
	var weapons := _hero.owned_weapons
	draw_circle(center, RADIUS + 12.0, Color(0.05, 0.03, 0.08, 0.55))
	for i in weapons.size():
		var at := center + Vector2.from_angle(slot_angle(i, weapons.size())) * RADIUS
		var highlighted := i == _highlight
		draw_circle(at, 10.0, Color(0.12, 0.08, 0.16, 0.95))
		if highlighted:
			draw_arc(at, 10.0, 0.0, TAU, 20, Color(1.0, 0.95, 0.7), 1.5)
		draw_texture_rect_region(ATLAS, Rect2(at - Vector2(8, 8), Vector2(16, 16)), weapons[i].sprite_region)
		var slots := [_hero.primary_weapon, _hero.secondary_weapon]
		for s in 2:
			if slots[s] == weapons[i]:
				draw_circle(at + Vector2(-3.0 + 6.0 * s, 11.0), 2.0, SLOT_COLORS[s])
