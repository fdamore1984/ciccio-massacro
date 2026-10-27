class_name Missile
extends Node2D
## Missile del bazooka sparato dal giocatore: cerca il nemico più vicino che
## può raggiungere (niente pareti o ostacoli in mezzo, vedi
## World.clear_line), lo insegue curvando e lo colpisce; se il bersaglio
## finisce dietro un ostacolo lo lascia e prosegue dritto. Senza nemici vola
## dritto ed esplode in aria.
## Non attraversa niente: si schianta contro rovine, macerie, casse e gli
## altri ostacoli solidi, contro le pareti più alte del suo volo, i palazzi
## e i muri degli interni.
## All'impatto esplode: lampo, palla di fuoco, fumo, detriti, segno a terra
## e telecamera che trema. Solo grafica e suono: il danno resta quello del
## colpo sul bersaglio. La fiamma del razzo illumina attorno (utile di notte).

const SPEED := 470.0
## Velocità con cui curva verso il bersaglio (radianti al secondo).
const TURN_RATE := 7.0
const LIFETIME := 2.6
## Cerca bersagli entro questa distanza.
const SEEK_RANGE := 650.0
const RADIUS := 10.0
const SIGHT_INTERVAL := 0.1
## Volando, resta sopra il terreno a questa altezza.
const FLIGHT_HEIGHT := 30.0
## Colpisce solo nemici più o meno alla sua altezza.
const HIT_HEIGHT_REACH := 70.0
## Durata dell'esplosione disegnata, raggio del fuoco e dei detriti.
const EXPLOSION_TIME := 0.6
const EXPLOSION_RADIUS := 62.0
const DEBRIS := 10
## Il segno a terra dell'esplosione (vedi GroundFx.shockwave).
const SCORCH_RADIUS := 70.0
const COLOR_CORE := Color(1.0, 0.95, 0.6)
const COLOR_FLAME := Color(1.0, 0.45, 0.1)
const COLOR_SMOKE := Color(0.3, 0.29, 0.28)
const COLOR_HULL := Color(0.4, 0.45, 0.32)
const COLOR_WARHEAD := Color(0.75, 0.2, 0.15)

var damage := 20
var direction := Vector2.RIGHT
## Altezza del terreno da cui è partito: il missile resta a quella quota.
var altitude := 0.0

## Bersaglio scelto da chi la lancia (il nemico agganciato), o null.
var target: Enemy
var _target: Enemy
var _age := 0.0
## La linea di vista verso il bersaglio si ricontrolla a intervalli.
var _sight_check := 0.0
var _exploding := 0.0
var _trail: Array[Vector2] = []
var _light := PointLight2D.new()
var _seed := randi()


func _ready() -> void:
	z_index = 5
	_light.texture = LightTexture.get_texture()
	_light.color = Color(1.0, 0.6, 0.3)
	_light.energy = 0.9
	_light.texture_scale = 0.7
	add_child(_light)
	_target = target if target and is_instance_valid(target) and not target.is_dead() and _can_reach(target) else _find_target()


func _physics_process(delta: float) -> void:
	_age += delta
	if _exploding > 0.0:
		_exploding += delta
		_light.energy = 2.2 * (1.0 - _exploding / EXPLOSION_TIME)
		_light.texture_scale = 1.4
		queue_redraw()
		if _exploding >= EXPLOSION_TIME:
			queue_free()
		return
	_sight_check -= delta
	if _target == null or not is_instance_valid(_target) or _target.is_dead():
		_target = _find_target() if _sight_check <= 0.0 else null
		_sight_check = SIGHT_INTERVAL
	elif _sight_check <= 0.0:
		_sight_check = SIGHT_INTERVAL
		if not _can_reach(_target):
			_target = _find_target()
	if _target:
		var wanted := (_target.global_position - global_position).normalized()
		direction = Vector2.from_angle(rotate_toward(direction.angle(), wanted.angle(), TURN_RATE * delta))
	_trail.push_front(position)
	if _trail.size() > 14:
		_trail.pop_back()
	position += direction * SPEED * delta
	# La luce cade a terra sotto il missile, come un'ellisse isometrica.
	_light.position.y = -altitude
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dead() or absf(enemy.ground_elevation - altitude) > HIT_HEIGHT_REACH:
			continue
		if global_position.distance_to(enemy.global_position) < RADIUS + enemy.radius:
			_explode(enemy)
			return
	if _hits_scenery():
		_explode(null, true)
		return
	if _age >= LIFETIME:
		_explode(null)
	queue_redraw()


## Contro un ostacolo solido, una parete più alta della quota di volo, una
## palazzo o un muro: lì il missile si schianta.
func _hits_scenery() -> bool:
	var world := World.current
	return world != null and world.blocks_projectile(global_position, altitude, FLIGHT_HEIGHT, RADIUS)


## Il nemico è alla quota del missile e nessun ostacolo sta in mezzo.
func _can_reach(enemy: Enemy) -> bool:
	if absf(enemy.ground_elevation - altitude) > HIT_HEIGHT_REACH:
		return false
	var world := World.current
	return world == null or world.clear_line(global_position, enemy.global_position, altitude, FLIGHT_HEIGHT)


func _find_target() -> Enemy:
	var best: Enemy = null
	var best_distance := SEEK_RANGE
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dead():
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < best_distance and _can_reach(enemy):
			best = enemy
			best_distance = distance
	return best


## crashed: si è schiantata contro un ostacolo o una parete (si sente forte).
func _explode(enemy: Enemy, crashed := false) -> void:
	_exploding = 0.001
	if enemy:
		enemy.take_damage(damage, direction, true)
		HitFeedback.hit(get_tree(), 0.05)
	Sfx.play("explosion", global_position, 1.0, 0.0 if enemy or crashed else -4.0)
	GroundFx.shockwave(global_position, altitude, SCORCH_RADIUS)
	if World.current and World.current.player:
		var player := World.current.player as Player
		if player and player.global_position.distance_to(global_position) < 700.0:
			player.shake(0.55)


func _draw() -> void:
	var lift := Vector2(0, -altitude - FLIGHT_HEIGHT)
	if _exploding > 0.0:
		_draw_explosion(lift, _exploding / EXPLOSION_TIME)
		return
	# Ombra a terra e scia di fumo che si allarga e svanisce.
	Shapes.disc(self, Vector2(0, -altitude + 6.0), RADIUS * 0.8, Color(0, 0, 0, 0.2))
	for i in _trail.size():
		var fade := 1.0 - float(i) / _trail.size()
		Shapes.disc(self, _trail[i] - position + lift, RADIUS * (1.4 - 0.8 * fade), Color(COLOR_SMOKE, 0.45 * fade))
	# Fiamma dello scarico che tremola, dietro al razzo.
	var forward := direction
	var across := forward.orthogonal()
	var tail := lift - forward * 13.0
	var flicker := 1.0 + 0.25 * sin(_age * 60.0)
	Shapes.disc(self, tail - forward * 5.0 * flicker, 7.0 * flicker, Color(COLOR_FLAME, 0.8))
	Shapes.disc(self, tail - forward * 2.0, 3.5, COLOR_CORE)
	# Razzo: corpo verde militare, alette in coda e testata rossa.
	var hull := PackedColorArray([COLOR_HULL])
	draw_primitive(PackedVector2Array([tail + across * 3.5, lift + forward * 8.0 + across * 3.5, lift + forward * 8.0 - across * 3.5, tail - across * 3.5]), hull, PackedVector2Array())
	draw_primitive(PackedVector2Array([tail + across * 3.5, tail + forward * 5.0 + across * 3.5, tail - forward * 2.0 + across * 8.0]), hull, PackedVector2Array())
	draw_primitive(PackedVector2Array([tail - across * 3.5, tail + forward * 5.0 - across * 3.5, tail - forward * 2.0 - across * 8.0]), hull, PackedVector2Array())
	draw_primitive(PackedVector2Array([lift + forward * 8.0 + across * 3.5, lift + forward * 15.0, lift + forward * 8.0 - across * 3.5]),
			PackedColorArray([COLOR_WARHEAD]), PackedVector2Array())
	draw_line(lift - forward * 4.0 + across * 3.5, lift - forward * 4.0 - across * 3.5, COLOR_HULL.darkened(0.4), 2.0)


## Esplosione (t da 0 a 1): lampo bianco, palla di fuoco che si gonfia e si
## scurisce, anello d'urto, detriti che volano via e fumo che sale.
func _draw_explosion(at: Vector2, t: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var grow := ease(t, 0.35)
	for k in 6:
		var drift := Vector2(rng.randf_range(-1.0, 1.0) * 26.0, -rng.randf_range(10.0, 50.0)) * grow
		Shapes.disc(self, at + drift, EXPLOSION_RADIUS * (0.35 + 0.35 * grow) * rng.randf_range(0.7, 1.1), Color(COLOR_SMOKE, 0.55 * (1.0 - t)))
	var fire := EXPLOSION_RADIUS * (0.3 + 0.7 * grow)
	Shapes.glow(self, at, fire * 1.6, Color(COLOR_FLAME, 0.6 * (1.0 - t)))
	Shapes.disc(self, at, fire * (1.0 - 0.4 * t), Color(COLOR_FLAME.lerp(COLOR_SMOKE, t), 0.85 * (1.0 - t)))
	Shapes.disc(self, at, fire * 0.55 * (1.0 - t), Color(COLOR_CORE, 1.0 - t))
	draw_arc(at, EXPLOSION_RADIUS * (0.4 + 1.1 * grow), 0.0, TAU, 32, Color(1.0, 0.9, 0.7, 0.8 * (1.0 - t)), 4.0 * (1.0 - t) + 1.0)
	for k in DEBRIS:
		var angle := rng.randf() * TAU
		var speed := rng.randf_range(0.6, 1.3)
		var fly := Vector2.from_angle(angle) * EXPLOSION_RADIUS * 1.5 * speed * grow + Vector2(0, 60.0 * t * t)
		Shapes.disc(self, at + fly, rng.randf_range(1.5, 3.5) * (1.0 - t * 0.5), Color(1.0, 0.7, 0.3, 1.0 - t) if k % 2 == 0 else Color(0.15, 0.13, 0.12, 1.0 - t))
	if t < 0.15:
		Shapes.disc(self, at, EXPLOSION_RADIUS * 1.2, Color(1, 1, 1, 0.6 * (1.0 - t / 0.15)))
