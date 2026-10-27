class_name EnemyBolt
extends Node2D
## Proiettile sparato dai nemici con la pistola o col fucile (e dalla
## doppietta del boss, più grossi, vedi radius): vola dritto e colpisce il
## giocatore (si può schivare, saltare o parare come gli altri colpi). Se il giocatore fluttua a mezz'aria caricando lo slam aereo il
## colpo sale verso di lui e lo raggiunge (vedi Player.receive_hit).
## Non attraversa pareti, palazzi, muri e ostacoli solidi: lì si ferma con
## una scintilla. Colpisce anche gli altri nemici che incontra (fuoco amico,
## vedi Enemy.hurt_enemy), mai chi l'ha sparato.

const RADIUS := 9.0
const FLIGHT_HEIGHT := 26.0
const HIT_HEIGHT_REACH := 50.0

var direction := Vector2.RIGHT
var speed := 260.0
var damage := 1
var max_distance := 600.0
var altitude := 0.0
## Colore del tracciante.
var color := Color(1.0, 0.8, 0.35)
## Grandezza del proiettile (per collisioni e disegno).
var radius := RADIUS
## Il nemico che l'ha sparato (non viene colpito dal suo proiettile) e il
## suo livello di minaccia (per i danni del fuoco amico, anche se intanto muore).
var shooter: Enemy
var threat_level := 1

var _travelled := 0.0
var _age := 0.0
## Quanto si è alzato in volo verso il giocatore sospeso a mezz'aria.
var _rise := 0.0


func _ready() -> void:
	z_index = 5


func _physics_process(delta: float) -> void:
	_age += delta
	var step := direction * speed * delta
	position += step
	_travelled += step.length()
	var player := World.current.player as Player if World.current else null
	if player:
		# Verso il giocatore sospeso a mezz'aria il colpo sale (il corpo sta
		# sopra le gambe), altrimenti torna all'altezza di volo.
		var wanted := 0.0
		if player.is_air_charging():
			wanted = maxf(player.altitude() - altitude + Player.LEG_LENGTH - FLIGHT_HEIGHT, 0.0)
		_rise = move_toward(_rise, wanted, speed * delta)
	if player and not player.is_dead() and absf(player.ground_elevation - altitude) <= HIT_HEIGHT_REACH \
			and position.distance_to(player.position) < radius + Player.RADIUS:
		# Il colpo arriva da dove si trova il dardo: la parata frontale funziona,
		# anche appena alzata (la parata è istantanea e gira subito il giocatore).
		var result := player.receive_hit(position - direction * 40.0, damage, true)
		if result != "ignored":
			if result in ["blocked", "parried", "broken"]:
				# Parato: il proiettile rimbalza sulla motosega con un lampo.
				HitSpark.spawn(get_parent(), position, altitude + FLIGHT_HEIGHT + _rise, 30.0, Player.COLOR_GUARD_SPARK)
			queue_free()
			return
	if _hit_enemy():
		queue_free()
		return
	if World.current and World.current.blocks_projectile(position, altitude, FLIGHT_HEIGHT, radius):
		HitSpark.spawn(get_parent(), position, altitude + FLIGHT_HEIGHT, 12.0, color)
		queue_free()
		return
	if _travelled >= max_distance:
		queue_free()
	queue_redraw()


## Fuoco amico: il primo altro nemico toccato, alla stessa altezza, viene
## ferito come da un colpo di chi ha sparato. Restituisce true se ha colpito.
func _hit_enemy() -> bool:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or (is_instance_valid(shooter) and enemy == shooter) or enemy.is_dead() \
				or absf(enemy.ground_elevation - altitude) > HIT_HEIGHT_REACH:
			continue
		if position.distance_to(enemy.position) < radius + enemy.radius:
			Enemy.hurt_enemy(enemy, damage, threat_level, direction, false)
			HitSpark.spawn(get_parent(), position, altitude + FLIGHT_HEIGHT, 12.0, color)
			return true
	return false


## Proiettile: un tracciante luminoso allungato nella direzione del volo,
## con la scia che svanisce dietro (più lunga per i colpi più veloci).
func _draw() -> void:
	var lift := Vector2(0, -altitude - FLIGHT_HEIGHT - _rise)
	Shapes.disc(self, Vector2(0, -altitude + 4.0), radius * 0.4, Color(0, 0, 0, 0.2))
	var trail := clampf(speed / 12.0, 14.0, 40.0)
	var width := maxf(radius * 0.45, 2.5)
	draw_line(lift - direction * trail, lift, Color(color, 0.45), width)
	draw_line(lift - direction * trail * 0.4, lift, Color(color, 0.85), width * 0.8)
	Shapes.disc(self, lift, width * 0.75, Color(1.0, 1.0, 0.85))
