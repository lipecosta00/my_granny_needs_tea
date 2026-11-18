extends Node
## Combat feedback service (GDD: "Feedback de cada golpe"): hitstop, screen
## shake, damage numbers, particles, sound and rumble behind one API, so
## gameplay code says *what* happened and tuning lives here.

const SFX := {
	&"swing": preload("res://assets/sfx/swing.wav"),
	&"hit": preload("res://assets/sfx/hit.wav"),
	&"hit_heavy": preload("res://assets/sfx/hit_heavy.wav"),
	&"roll": preload("res://assets/sfx/roll.wav"),
	&"hurt": preload("res://assets/sfx/hurt.wav"),
	&"enemy_die": preload("res://assets/sfx/enemy_die.wav"),
	&"charge_ready": preload("res://assets/sfx/charge_ready.wav"),
	&"spider_warn": preload("res://assets/sfx/spider_warn.wav"),
	&"spark": preload("res://assets/sfx/spark.wav"),
	&"flash": preload("res://assets/sfx/flash.wav"),
	&"gate_open": preload("res://assets/sfx/gate_open.wav"),
	&"pet_out": preload("res://assets/sfx/pet_out.wav"),
	&"fizzle": preload("res://assets/sfx/fizzle.wav"),
}
const DIGITS := preload("res://assets/kenney/tiny_battle/tilemap_packed.png")
const DIGIT_ROW := 10  # Tiny Battle: digits 0-9 at (0..9, 10)
const SFX_VOICES := 8

## Hitstop durations (GDD: 0.06 s normal, 0.1 s big impact).
@export var hitstop_normal := 0.06
@export var hitstop_big := 0.1
## Headless tests step physics frame by frame; a frozen time scale would
## desync them, so they switch hitstop off.
var hitstop_enabled := true
## Headless runs use a dummy audio driver that never releases playbacks.
var sfx_enabled := true

var _hitstop_until_ms := 0
var _hitstop_serial := 0
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _layer: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in SFX_VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = &"Master"
		add_child(voice)
		_voices.append(voice)
	# Own layer that follows the camera: numbers read clearly, untouched by
	# the map's CanvasModulate night tint.
	_layer = CanvasLayer.new()
	_layer.layer = 5
	_layer.follow_viewport_enabled = true
	add_child(_layer)


## Freezes gameplay briefly. Overlapping requests extend, never shorten.
func hitstop(duration: float) -> void:
	if not hitstop_enabled:
		return
	var until := Time.get_ticks_msec() + int(duration * 1000.0)
	if until <= _hitstop_until_ms:
		return
	_hitstop_until_ms = until
	# Only the latest request restores time. Comparing clocks instead would
	# leave the game frozen when the timer fires a millisecond early.
	_hitstop_serial += 1
	var serial := _hitstop_serial
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration, true, false, true).timeout
	if serial == _hitstop_serial:
		Engine.time_scale = 1.0
		_hitstop_until_ms = 0


func shake(trauma: float) -> void:
	if not Settings.screen_shake_enabled:
		return
	for camera in get_tree().get_nodes_in_group(&"shake_camera"):
		camera.add_trauma(trauma)


func rumble(weak: float, strong: float, duration: float) -> void:
	if not Settings.vibration_enabled:
		return
	for device in Input.get_connected_joypads():
		Input.start_joy_vibration(device, weak, strong, duration)


func sfx(sound: StringName, pitch_jitter := 0.06) -> void:
	if not sfx_enabled:
		return
	var stream: AudioStream = SFX.get(sound)
	if stream == null:
		push_warning("unknown sfx %s" % sound)
		return
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = stream
	voice.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	voice.play()


## Number rising from [param world_pos] (Tiny Battle digits).
func damage_number(world_pos: Vector2, amount: int, color := Color.WHITE) -> void:
	var number := Node2D.new()
	number.position = world_pos + Vector2(randf_range(-3, 3), -14)
	number.modulate = color
	var digits := str(amount)
	for i in digits.length():
		var glyph := Sprite2D.new()
		glyph.texture = DIGITS
		glyph.region_enabled = true
		glyph.region_rect = Rect2(int(digits[i]) * 16, DIGIT_ROW * 16, 16, 16)
		glyph.position.x = (i - (digits.length() - 1) / 2.0) * 7.0
		number.add_child(glyph)
	_layer.add_child(number)
	# Freezes with hitstop too (Godot 4.3 tweens follow Engine.time_scale).
	var tween := number.create_tween()
	tween.tween_property(number, "position:y", number.position.y - 10.0, 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(number, "modulate:a", 0.0, 0.2).set_delay(0.3)
	tween.tween_callback(number.queue_free)


## Expanding ring (Clarão, gate opening). Drawn untinted on the Fx layer.
func ring(world_pos: Vector2, radius: float, color: Color, duration := 0.3) -> void:
	var ring_node := RingFx.new()
	ring_node.position = world_pos
	ring_node.color = color
	_layer.add_child(ring_node)
	var tween := ring_node.create_tween()
	tween.tween_property(ring_node, "radius", radius, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ring_node, "modulate:a", 0.0, duration).set_delay(duration * 0.4)
	tween.tween_callback(ring_node.queue_free)


## Square-pixel burst for hits and deaths.
func burst(world_pos: Vector2, color: Color, amount := 8, speed := 70.0) -> void:
	var particles := CPUParticles2D.new()
	particles.position = world_pos
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = 0.35
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = speed * 0.5
	particles.initial_velocity_max = speed
	particles.damping_min = speed * 2.0
	particles.damping_max = speed * 2.5
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.color = color
	_world_parent().add_child(particles)
	particles.emitting = true
	particles.finished.connect(particles.queue_free)


func _world_parent() -> Node:
	var scene := get_tree().current_scene
	return scene if scene else get_tree().root
