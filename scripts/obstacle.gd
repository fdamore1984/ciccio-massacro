class_name Obstacle
extends Node2D
## Ostacolo del mondo, disegnato con forme geometriche. I tipi hanno ancora
## i nomi di prima (dati e salvataggi), ma l'aspetto è quello della città
## distrutta: "tree" è un albero secco (sui viali e nei parchi), "lamp" un
## lampione piegato, "shelter" una pensilina dell'autobus sfasciata,
## "metro" l'ingresso della metropolitana (scale che scendono nel buio, la
## ringhiera e il cartello con la M: ci si scende come nelle porte degli
## edifici), "bench" una panchina e "corpse" un corpo a terra sulle
## banchine della metro, "rock" un blocco di macerie, "bush"
## un cumulo di rottami che rallenta, "chest" una cassa militare, "totem" la sirena al centro di
## un'arena, "merchant" il banco di un commerciante, "cave" la porta di un
## edificio abbandonato, "stairs" le scale verso il piano dopo ed "exit"
## l'uscita all'aperto. La posizione è la base a terra, così
## l'ordinamento per y lo mette davanti o dietro ai personaggi; viene
## disegnato più in alto quanto il blocco di terreno su cui si trova. Gli effetti (blocco,
## rallentamento) sono gestiti da World.

## La parte alta di alberi, lampioni e pensiline diventa trasparente quando
## il giocatore ci passa dietro.
const CANOPY_FADE_ALPHA := 0.4
## Elementi con cui si interagisce: in modalità focus restano a colori con
## un'aura bianca attorno (vedi LowHealthVignette).
const INTERACTIVE := ["chest", "cave", "metro", "stairs", "exit", "merchant", "totem"]
const COLOR_AURA := Color(1, 1, 1, 0.55)
## Ostacoli alti, che sfumano quando il giocatore ci passa dietro.
const TALL := ["tree", "lamp", "shelter"]
## Urto del giocatore (vedi flash): luminosità in più e durata.
const FLASH_BOOST := 0.7
const FLASH_TIME := 0.3

var type_id := ""
var radius := 20.0
var _type: Dictionary
var _variant := 0
var _canopy_alpha := 1.0
var _opened := false
## Altezza del terreno sotto l'ostacolo.
var _lift := 0.0
## Ingresso della caverna: direzione della parete in cui si apre.
var _edge := Vector2.RIGHT
## Aura della modalità focus disegnata adesso.
var _aura_shown := false
var _flash_tween: Tween


func setup(data: Dictionary, type: Dictionary) -> void:
	type_id = data["type"]
	radius = data["radius"]
	position = data["position"]
	_variant = data["variant"]
	_lift = data["elevation"]
	_type = type
	_edge = data.get("edge", Vector2.RIGHT)
	# Disegnato una volta sola; solo gli alberi controllano il giocatore e
	# il totem si anima.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	set_process(type_id in TALL or type_id in INTERACTIVE)
	if type_id in INTERACTIVE:
		add_to_group(LowHealthVignette.FOCUS_GROUP)


## Il giocatore ci è appena andato a sbattere: l'ostacolo si illumina per un
## attimo (solo lui, senza contorni attorno).
func flash() -> void:
	if _flash_tween and _flash_tween.is_running():
		return
	modulate = Color(1.0 + FLASH_BOOST, 1.0 + FLASH_BOOST, 1.0 + FLASH_BOOST)
	_flash_tween = create_tween()
	_flash_tween.tween_property(self, "modulate", Color.WHITE, FLASH_TIME)


## Si può ancora usare (cassa chiusa, caverna non completata, totem pronto).
func _is_active() -> bool:
	var world := World.current
	match type_id:
		"chest":
			return not _opened
		"cave", "metro":
			return world == null or not world.is_cave_cleared(position)
		"totem":
			return world == null or world.totem_state(position) == "ready"
	return type_id in INTERACTIVE


## Modalità focus: dove resta a colori e quanto è grande (raggio 0: no).
func focus_spot() -> Vector3:
	if not _is_active():
		return Vector3.ZERO
	var at := global_position - Vector2(0, _lift + _aura_height())
	return Vector3(at.x, at.y, radius * 2.2)


## Altezza del centro dell'aura sopra la base.
func _aura_height() -> float:
	match type_id:
		"chest":
			return radius * 0.6
		"metro":
			return radius * 0.3
		"merchant":
			return radius * 1.4
		"totem":
			return radius * 1.4
	# Archi nella parete.
	return radius


func _process(_delta: float) -> void:
	if type_id in INTERACTIVE:
		var aura := LowHealthVignette.focus_held() and _is_active()
		if aura != _aura_shown:
			_aura_shown = aura
			queue_redraw()
	if type_id in ["cave", "metro"]:
		return
	if type_id in ["totem", "merchant", "stairs", "exit"]:
		queue_redraw()
		return
	if type_id == "chest":
		# Brilla finché è chiusa; poi si ridisegna aperta.
		_opened = World.current != null and World.current.is_chest_opened(position)
		queue_redraw()
		return
	var player: Node2D = World.current.player if World.current else null
	var target := 1.0
	if player:
		# Confronto sullo schermo: anche il giocatore è disegnato alla sua altezza.
		var player_lift: float = World.current.elevation_at(player.global_position)
		var offset := player.global_position - Vector2(0, player_lift) - (global_position - Vector2(0, _lift))
		# Dietro l'albero (più in alto sullo schermo) e sotto la chioma.
		if offset.y < 0.0 and offset.y > -radius * 3.2 and absf(offset.x) < radius * 1.1:
			target = CANOPY_FADE_ALPHA
	if not is_equal_approx(target, _canopy_alpha):
		_canopy_alpha = move_toward(_canopy_alpha, target, 0.1)
		queue_redraw()


func _color(index: int) -> Color:
	var colors: Array = _type["colors"]
	var color: Array = colors[index % colors.size()]
	return Color(color[0], color[1], color[2])


func _type_color(key: String) -> Color:
	var color: Array = _type[key]
	return Color(color[0], color[1], color[2])


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _variant
	draw_set_transform(Vector2(0, -_lift))
	if _aura_shown:
		Shapes.glow(self, Vector2(0, -_aura_height()), radius * 2.4, COLOR_AURA)
	match type_id:
		"tree":
			_draw_tree(rng)
		"lamp":
			_draw_lamp(rng)
		"shelter":
			_draw_shelter(rng)
		"metro":
			_draw_metro()
		"bench":
			_draw_bench(rng)
		"corpse":
			_draw_corpse(rng)
		"rock":
			_draw_rock(rng)
		"bush":
			_draw_bush(rng)
		"totem":
			_draw_totem()
		"chest":
			_draw_chest()
		"merchant":
			_draw_merchant()
		"cave":
			_draw_cave()
		"stairs":
			_draw_stairs()
		"exit":
			_draw_exit()


func _draw_shadow(width: float) -> void:
	draw_set_transform(Vector2(0, -_lift), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, width, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2(0, -_lift))


## Albero secco: tronco storto e rami spogli, qualcuno spezzato. La
## chioma (i rami) sfuma quando il giocatore ci passa dietro.
func _draw_tree(rng: RandomNumberGenerator) -> void:
	_draw_shadow(radius * 0.7)
	var bark := _color(rng.randi())
	var trunk := Color(bark, 1.0)
	var top := Vector2(rng.randf_range(-0.25, 0.25) * radius, -radius * rng.randf_range(2.2, 2.8))
	var bend := Vector2(top.x * 0.4 + rng.randf_range(-4.0, 4.0), top.y * 0.5)
	draw_polyline(PackedVector2Array([Vector2.ZERO, bend, top]), trunk, maxf(radius * 0.22, 4.0))
	var branches := PackedVector2Array()
	var twigs := PackedVector2Array()
	for k in rng.randi_range(4, 6):
		var t := rng.randf_range(0.45, 1.0)
		var from := bend.lerp(top, (t - 0.45) / 0.55) if t > 0.45 else bend
		var angle := -PI / 2.0 + rng.randf_range(-1.2, 1.2)
		var length := radius * rng.randf_range(0.6, 1.1)
		var to := from + Vector2.from_angle(angle) * length
		branches.append_array([from, to])
		for j in 2:
			twigs.append_array([to, to + Vector2.from_angle(angle + rng.randf_range(-0.8, 0.8)) * length * 0.4])
	draw_multiline(branches, Color(bark, _canopy_alpha), 3.0)
	draw_multiline(twigs, Color(bark.lightened(0.1), _canopy_alpha), 1.5)


## Lampione piegato con la lampada rotta.
func _draw_lamp(_rng: RandomNumberGenerator) -> void:
	_draw_shadow(radius * 0.6)
	var metal := _color(0)
	var top := Vector2(radius * 0.15, -radius * 4.2)
	var bend := top + Vector2(radius * 1.1, radius * 0.4)
	var pole := Color(metal, _canopy_alpha)
	draw_rect(Rect2(-radius * 0.35, -radius * 0.35, radius * 0.7, radius * 0.35), metal.darkened(0.3))
	draw_line(Vector2.ZERO, top, pole, 5.0)
	draw_line(top, bend, pole, 4.0)
	draw_colored_polygon(PackedVector2Array([bend + Vector2(-6, 0), bend + Vector2(6, 0), bend + Vector2(3, 6), bend + Vector2(-3, 6)]), Color(metal.darkened(0.3), _canopy_alpha))


## Pensilina dell'autobus sfasciata: due pali, il tetto storto, il vetro
## crepato e la panchina.
func _draw_shelter(rng: RandomNumberGenerator) -> void:
	_draw_shadow(radius * 1.1)
	var metal := _color(0)
	var glass := _color(1)
	var width := radius * 1.1
	var height := radius * 2.2
	var tilt := rng.randf_range(-8.0, 8.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-width * 0.9, -4), Vector2(width * 0.9, -4), Vector2(width * 0.9, -height * 0.85 + tilt * 0.5), Vector2(-width * 0.9, -height * 0.85 - tilt * 0.5)]),
			Color(glass, 0.25 * _canopy_alpha))
	draw_line(Vector2(-width * 0.2, -height * 0.7), Vector2(width * 0.3, -height * 0.3), Color(1, 1, 1, 0.35 * _canopy_alpha), 1.5)
	draw_rect(Rect2(-width * 0.7, -radius * 0.55, width * 1.4, 5.0), metal.darkened(0.2))
	for x: float in [-width, width]:
		draw_line(Vector2(x, 0), Vector2(x, -height + (tilt if x > 0 else -tilt) * 0.5), Color(metal, _canopy_alpha), 4.0)
	draw_line(Vector2(-width - 6.0, -height - tilt * 0.5), Vector2(width + 6.0, -height + tilt * 0.5), Color(metal.darkened(0.15), _canopy_alpha), 6.0)


## Ingresso della metropolitana: un'apertura nel marciapiede con le scale
## che scendono nel buio, la ringhiera arrugginita attorno e il palo col
## cartello rosso con la M.
func _draw_metro() -> void:
	var dark := _color(0)
	var rail := _color(1)
	var sign_color := _type_color("sign")
	var half := Vector2(radius * 0.75, radius * 0.4)
	var hole := PackedVector2Array([Vector2(-half.x, 0), Vector2(0, -half.y), Vector2(half.x, 0), Vector2(0, half.y)])
	draw_colored_polygon(hole, dark)
	# Gradini che scendono verso il fondo.
	var steps := PackedVector2Array()
	for k in 4:
		var t := (k + 1) / 5.0
		steps.append_array([hole[0].lerp(hole[1], t) + Vector2(0, 2.0 + k), hole[3].lerp(hole[2], t) + Vector2(0, 2.0 + k)])
	draw_multiline(steps, Color(rail, 0.45), 2.0)
	# Ringhiera su tre lati.
	var posts := [hole[0], hole[1], hole[2], hole[3]]
	for k in 3:
		var from: Vector2 = posts[k]
		var to: Vector2 = posts[k + 1]
		draw_line(from - Vector2(0, 14), to - Vector2(0, 14), rail, 3.0)
		draw_line(from, from - Vector2(0, 14), rail, 2.0)
	draw_line(hole[3], hole[3] - Vector2(0, 14), rail, 2.0)
	# Palo col cartello.
	var pole := hole[2] + Vector2(6, 0)
	draw_line(pole, pole - Vector2(0, radius * 1.6), rail.darkened(0.2), 3.0)
	var board := pole - Vector2(0, radius * 1.6 + 8.0)
	var cleared := World.current != null and World.current.is_cave_cleared(position)
	draw_rect(Rect2(board - Vector2(9, 9), Vector2(18, 18)), _type_color("cleared") if cleared else sign_color)
	draw_polyline(PackedVector2Array([board + Vector2(-5, 5), board + Vector2(-5, -5), board + Vector2(0, 1), board + Vector2(5, -5), board + Vector2(5, 5)]), Color(0.95, 0.95, 0.9), 2.0)
	if cleared:
		# Stazione ripulita: grata di traverso sulle scale.
		var bars := PackedVector2Array()
		for k in 5:
			var t := (k + 0.5) / 5.0
			bars.append_array([hole[0].lerp(hole[1], t) - Vector2(0, 3), hole[3].lerp(hole[2], t) - Vector2(0, 3)])
		draw_multiline(bars, rail.lightened(0.15), 3.0)
		return
	# Dal buio sale un alito verdastro.
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 600.0)
	draw_circle(Vector2(0, -4), radius * 0.3, Color(0.4, 0.7, 0.35, 0.06 + 0.06 * pulse))


## Panchina della metro: seduta e schienale di assi su due piedi di ferro,
## lungo i binari (in diagonale come la banchina).
func _draw_bench(rng: RandomNumberGenerator) -> void:
	_draw_shadow(radius * 0.9)
	var wood := _color(0)
	var metal := _color(1)
	var along := Vector2(1.0, 0.5).normalized() * radius
	var across := Vector2(-1.0, 0.5).normalized() * radius * 0.25
	var seat := Vector2(0, -12)
	for side: float in [-0.75, 0.75]:
		draw_line(along * side, along * side + seat, metal, 3.0)
	draw_colored_polygon(PackedVector2Array([seat - along - across, seat + along - across, seat + along + across, seat - along + across]), wood)
	var back := seat - across - Vector2(0, 12)
	draw_colored_polygon(PackedVector2Array([seat - along - across, seat + along - across, back + along, back - along]), wood.darkened(0.2))
	if rng.randf() < 0.3:
		# Un'asse spezzata.
		draw_line(back + along * 0.2, back + along * 0.7 + Vector2(0, 8), wood.darkened(0.5), 2.0)


## Corpo a terra sulla banchina, in una pozza di sangue: rallenta un poco.
func _draw_corpse(rng: RandomNumberGenerator) -> void:
	var blood := _type_color("blood")
	draw_set_transform(Vector2(0, -_lift), 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2(rng.randf_range(-6, 6), 4), radius * 1.3, Color(blood, 0.8))
	draw_set_transform(Vector2(0, -_lift))
	var cloth := _color(rng.randi())
	var angle := rng.randf_range(-0.4, 0.4)
	var axis := Vector2.from_angle(angle) * radius
	var body := PackedVector2Array()
	for k in 10:
		var a := TAU * k / 10.0
		body.append(Vector2(cos(a), sin(a) * 0.38).rotated(angle) * radius)
	draw_colored_polygon(body, cloth)
	draw_circle(axis * 1.1 + Vector2(0, -2), radius * 0.32, Color(0.55, 0.5, 0.45))
	draw_line(-axis * 0.2, -axis * 0.2 + Vector2(-radius * 0.4, radius * 0.4), Enemy.COLOR_LIMBS, 2.5)
	draw_line(axis * 0.3, axis * 0.3 + Vector2(radius * 0.3, -radius * 0.45), Enemy.COLOR_LIMBS, 2.5)


## Blocco di macerie di cemento con la faccia superiore più chiara e i
## tondini di ferro che spuntano.
func _draw_rock(rng: RandomNumberGenerator) -> void:
	_draw_shadow(radius * 1.05)
	var color := _color(rng.randi())
	var points := PackedVector2Array()
	var sides := rng.randi_range(4, 6)
	for k in sides:
		var angle := TAU * k / sides + rng.randf_range(-0.25, 0.25)
		points.append(Vector2(cos(angle), sin(angle) * 0.75) * radius * rng.randf_range(0.8, 1.05) + Vector2(0, -radius * 0.45))
	draw_colored_polygon(points, color.darkened(0.15))
	var top := PackedVector2Array()
	for point in points:
		top.append(point * 0.65 + Vector2(0, -radius * 0.35))
	draw_colored_polygon(top, color.lightened(0.1))
	var rebar := _type_color("rebar")
	for k in 2:
		var from := top[k] * 0.6 + Vector2(0, -radius * 0.1)
		draw_line(from, from + Vector2(rng.randf_range(-0.4, 0.4), -1.0) * radius * 0.6, rebar, 2.0)
	points.append(points[0])
	draw_polyline(points, color.darkened(0.4), 2.0)


## Cumulo di rottami che rallenta: assi, lamiere, un copertone e pezzi
## arrugginiti.
func _draw_bush(rng: RandomNumberGenerator) -> void:
	_draw_shadow(radius * 0.95)
	var color := _color(rng.randi())
	for k in 4:
		var at := Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, -0.2)) * radius
		var along := Vector2.from_angle(rng.randf_range(-0.5, 0.5)) * radius * rng.randf_range(0.4, 0.7)
		var across := along.orthogonal().normalized() * radius * 0.15
		draw_colored_polygon(PackedVector2Array([at - along - across, at + along - across, at + along + across, at - along + across]),
				color.darkened(0.1 * k) if k % 2 == 0 else color.lightened(0.08))
	if rng.randf() < 0.6:
		var tire := Vector2(rng.randf_range(-0.3, 0.3), -0.45) * radius
		draw_arc(tire, radius * 0.32, 0.0, TAU, 16, Color(0.08, 0.08, 0.08), radius * 0.16)
	var rust := _type_color("rust")
	for k in 3:
		draw_circle(Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.8, -0.2)) * radius, 2.5, rust)


## Sirena d'allarme su un palo: tromba e luce lampeggiante verdi con un
## anello pulsante a terra quando si può avviare la sfida, rosse durante la
## sfida, spente dopo.
func _draw_totem() -> void:
	var state := World.current.totem_state(position) if World.current else "ready"
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 250.0)
	var glow := _type_color("glow")
	if state == "active":
		glow = _type_color("active")
		pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 90.0)
	elif state == "used":
		glow = _type_color("used")
	if state != "used":
		draw_set_transform(Vector2(0, -_lift), 0.0, Vector2(1.0, 0.5))
		draw_arc(Vector2.ZERO, radius * 2.2 + pulse * 10.0, 0.0, TAU, 40, Color(glow, 0.35 + 0.3 * pulse), 5.0)
		draw_set_transform(Vector2(0, -_lift))
	_draw_shadow(radius * 1.1)
	var metal := _type_color("metal")
	# Basamento di cemento e palo.
	draw_rect(Rect2(-radius * 0.7, -radius * 0.5, radius * 1.4, radius * 0.5), Color(0.45, 0.44, 0.42))
	draw_rect(Rect2(radius * 0.35, -radius * 0.5, radius * 0.35, radius * 0.5), Color(0.35, 0.34, 0.32))
	var top := Vector2(0, -radius * 2.6)
	draw_line(Vector2(0, -radius * 0.5), top, metal, 6.0)
	draw_line(Vector2(-2, -radius * 0.5), top + Vector2(-2, 0), metal.lightened(0.2), 2.0)
	# Due trombe della sirena ai lati.
	for side: float in [-1.0, 1.0]:
		var mouth := top + Vector2(side * radius * 0.95, radius * 0.1)
		draw_colored_polygon(PackedVector2Array([top + Vector2(side * 4.0, -4.0), mouth + Vector2(0, -radius * 0.35),
				mouth + Vector2(0, radius * 0.35), top + Vector2(side * 4.0, 4.0)]), metal.darkened(0.15))
		draw_line(mouth + Vector2(0, -radius * 0.35), mouth + Vector2(0, radius * 0.35), metal.darkened(0.45), 3.0)
	# Luce lampeggiante in cima.
	var lamp := top + Vector2(0, -9.0)
	if state != "used":
		draw_circle(lamp, 12.0 + 6.0 * pulse, Color(glow, 0.2 + 0.2 * pulse))
	draw_circle(lamp, 6.0, Color(glow, 0.6 + 0.4 * pulse) if state != "used" else glow)
	draw_rect(Rect2(lamp + Vector2(-7, 4), Vector2(14, 4)), metal.darkened(0.3))


## Cassa militare verde con le fasce di metallo e la croce bianca: chiusa
## brilla un poco, aperta mostra il coperchio alzato e l'interno vuoto.
func _draw_chest() -> void:
	_draw_shadow(radius * 1.2)
	var wood := _color(0)
	var metal := _type_color("metal")
	var width := radius * 1.3
	var height := radius * 0.9
	draw_rect(Rect2(-width, -height, width * 2.0, height), wood)
	draw_rect(Rect2(width * 0.55, -height, width * 0.45, height), wood.darkened(0.25))
	for x: float in [-width * 0.85, width * 0.65]:
		draw_rect(Rect2(x, -height, width * 0.14, height), metal.darkened(0.2))
	var mark := Vector2(-width * 0.15, -height * 0.5)
	draw_line(mark - Vector2(6, 0), mark + Vector2(6, 0), Color(0.9, 0.9, 0.85, 0.85), 3.0)
	draw_line(mark - Vector2(0, 6), mark + Vector2(0, 6), Color(0.9, 0.9, 0.85, 0.85), 3.0)
	if _opened:
		draw_rect(Rect2(-width, -height - 4.0, width * 2.0, 6.0), wood.darkened(0.6))
		draw_colored_polygon(PackedVector2Array([Vector2(-width, -height - 2.0), Vector2(width, -height - 2.0), Vector2(width * 0.9, -height - radius * 1.1), Vector2(-width * 0.9, -height - radius * 1.1)]), wood.lightened(0.05))
		return
	var lid := PackedVector2Array([Vector2(-width, -height), Vector2(width, -height), Vector2(width * 0.85, -height - radius * 0.6), Vector2(-width * 0.85, -height - radius * 0.6)])
	draw_colored_polygon(lid, wood.lightened(0.12))
	draw_rect(Rect2(-4.0, -height - 3.0, 8.0, 9.0), metal)
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 300.0)
	draw_circle(Vector2(width * 0.7, -height - radius * 0.7), 2.0 + pulse * 1.5, Color(1.0, 0.95, 0.6, 0.6 + 0.4 * pulse))


## Banco del commerciante: pali e telone rattoppato, il commerciante con il
## berretto e la maschera antigas al collo dietro un bancone di assi con la
## merce in mostra (kit medico, tanica, catena) e un'insegna con un
## ingranaggio che brilla, per riconoscerlo da lontano.
func _draw_merchant() -> void:
	_draw_shadow(radius * 1.5)
	var wood := _type_color("wood")
	var jacket := _type_color("jacket")
	var skin := _type_color("skin")
	var scrap := _type_color("scrap")
	var width := radius * 1.3
	var height := radius * 0.75
	var top := -height - radius * 2.0
	for x: float in [-width, width - 5.0]:
		draw_rect(Rect2(x, top, 5.0, radius * 2.0), Color(0.35, 0.35, 0.37))
	# Il commerciante dondola appena, come se respirasse.
	var breath := sin(Time.get_ticks_msec() / 400.0) * 1.5
	var body := Vector2(0, -height - 6.0 + breath * 0.5)
	draw_circle(body, radius * 0.42, jacket)
	var head := body + Vector2(0, -radius * 0.55 + breath * 0.3)
	draw_circle(head, radius * 0.28, skin)
	draw_circle(head + Vector2(-4, -1), 2.2, Color(0.1, 0.1, 0.1))
	draw_circle(head + Vector2(4, -1), 2.2, Color(0.1, 0.1, 0.1))
	# Berretto con la visiera e maschera antigas appesa al collo.
	draw_colored_polygon(PackedVector2Array([head + Vector2(-radius * 0.3, -radius * 0.08), head + Vector2(radius * 0.3, -radius * 0.08),
			head + Vector2(radius * 0.22, -radius * 0.32), head + Vector2(-radius * 0.22, -radius * 0.32)]), jacket.darkened(0.3))
	draw_line(head + Vector2(-radius * 0.05, -radius * 0.1), head + Vector2(radius * 0.45, -radius * 0.08), jacket.darkened(0.45), 3.0)
	draw_circle(body + Vector2(0, -radius * 0.2), radius * 0.16, Color(0.2, 0.22, 0.2))
	draw_circle(body + Vector2(0, -radius * 0.2), radius * 0.07, Color(0.5, 0.55, 0.5))
	# Telone inclinato a pezze, col bordo sfilacciato.
	var stripes := 6
	var back := top
	var front := top + radius * 0.45
	for k in stripes:
		var x0 := -width - 6.0 + (width * 2.0 + 12.0) * k / stripes
		var x1 := -width - 6.0 + (width * 2.0 + 12.0) * (k + 1) / stripes
		var color := _color(k).darkened(0.08 * (k % 3))
		draw_colored_polygon(PackedVector2Array([Vector2(x0 * 0.92, back), Vector2(x1 * 0.92, back), Vector2(x1, front), Vector2(x0, front)]), color)
		draw_line(Vector2(x0, front), Vector2((x0 + x1) / 2.0, front + 5.0), color.darkened(0.2), 2.0)
	# Bancone di assi con la merce.
	draw_rect(Rect2(-width, -height, width * 2.0, height), wood)
	draw_rect(Rect2(width * 0.6, -height, width * 0.4, height), wood.darkened(0.25))
	draw_line(Vector2(-width, -height * 0.5), Vector2(width, -height * 0.5), wood.darkened(0.35), 1.5)
	draw_rect(Rect2(-width - 4.0, -height - 5.0, width * 2.0 + 8.0, 6.0), wood.lightened(0.15))
	draw_rect(Rect2(-width * 0.75, -height - 14.0, 13.0, 9.0), Player.COLOR_MEDKIT)
	draw_line(Vector2(-width * 0.75 + 6.5, -height - 13.0), Vector2(-width * 0.75 + 6.5, -height - 6.0), Player.COLOR_HURT, 2.0)
	draw_rect(Rect2(-width * 0.3, -height - 16.0, 10.0, 11.0), Items.color("potion_mana"))
	BodyParts.draw_chainsaw(self, Vector2(width * 0.2, -height - 8.0), -0.25, 30.0, 3.0)
	# Insegna con l'ingranaggio sopra il telone.
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 300.0)
	var board := Vector2(0, top - 10.0)
	for k in 8:
		draw_line(board, board + Vector2.from_angle(TAU * k / 8.0) * 10.5, scrap.darkened(0.3), 4.0)
	draw_circle(board, 7.5, scrap)
	draw_circle(board, 3.0, scrap.darkened(0.5))
	draw_circle(board + Vector2(7, -7), 1.5 + pulse * 1.5, Color(1.0, 0.97, 0.7, 0.5 + 0.5 * pulse))


## Porta nella parete (edificio, scale, uscita): stipiti e architrave di
## cemento e vano del colore dato. Restituisce i punti del vano.
func _draw_arch(inside: Color) -> PackedVector2Array:
	var width := radius * 1.0
	var height := radius * 2.0
	var door := PackedVector2Array([_edge * -width, _edge * width, _edge * width + Vector2(0, -height), _edge * -width + Vector2(0, -height)])
	var frame := PackedVector2Array([_edge * -(width + 7.0), _edge * (width + 7.0), _edge * (width + 7.0) + Vector2(0, -height - 9.0),
			_edge * -(width + 7.0) + Vector2(0, -height - 9.0)])
	var concrete := _color(1)
	draw_colored_polygon(frame, concrete.darkened(0.2))
	draw_colored_polygon(door, inside)
	draw_line(_edge * -(width + 7.0) + Vector2(0, -height - 4.0), _edge * (width + 7.0) + Vector2(0, -height - 4.0), concrete.lightened(0.1), 5.0)
	draw_line(_edge * -(width + 3.0), _edge * -(width + 3.0) + Vector2(0, -height), concrete, 3.0)
	draw_line(_edge * (width + 3.0), _edge * (width + 3.0) + Vector2(0, -height), concrete, 3.0)
	return door


## Direzione dalla parete verso chi guarda (sul pavimento davanti all'arco).
func _out_of_wall() -> Vector2:
	var normal := _edge.orthogonal()
	return normal if normal.y > 0.0 else -normal


## Porta dell'edificio abbandonato: un vano buio nella parete del palazzo;
## sbarrata con le assi se l'edificio è già stato ripulito.
func _draw_cave() -> void:
	_draw_arch(_color(0))
	var width := radius * 1.0
	var height := radius * 2.0
	if World.current and World.current.is_cave_cleared(position):
		var planks := _type_color("cleared")
		for k in 3:
			var y := -height * (0.25 + 0.27 * k)
			draw_line(_edge * -width * 1.1 + Vector2(0, y + 6.0), _edge * width * 1.1 + Vector2(0, y - 6.0), planks.darkened(0.12 * k), 8.0)
		return
	# Un filo di polvere che esce dal buio.
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 500.0)
	draw_circle(Vector2(0, -height * 0.35), width * 0.35, Color(0.4, 0.5, 0.7, 0.08 + 0.06 * pulse))


## Porta delle scale verso il piano dopo: un vano buio nella parete, con i
## gradini che spariscono nel buio e la luce fredda di un neon dal fondo.
func _draw_stairs() -> void:
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 350.0)
	_draw_arch(_color(0))
	if _in_metro():
		_draw_escalator(false)
		return
	var width := radius * 1.0
	var height := radius * 2.0
	var stone := _color(1)
	for k in 4:
		var y := -3.0 - k * 7.0
		var w := width * (0.9 - k * 0.18)
		draw_line(_edge * -w + Vector2(0, y), _edge * w + Vector2(0, y), stone.darkened(0.25 + k * 0.15), 4.0)
	draw_circle(Vector2(0, -height * 0.55), width * 0.4, Color(_type_color("glow"), 0.12 + 0.18 * pulse))


## Uscita all'aperto: una porta nella parete piena di luce calda, che si
## allunga sul pavimento davanti.
func _draw_exit() -> void:
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 400.0)
	var light := _type_color("glow")
	var out := _out_of_wall()
	draw_set_transform(Vector2(0, -_lift) + out * radius * 0.8, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, radius * 1.2, Color(light, 0.12 + 0.08 * pulse))
	draw_set_transform(Vector2(0, -_lift))
	_draw_arch(Color(light, 0.85))
	var height := radius * 2.0
	draw_circle(Vector2(0, -height * 0.45), radius * 0.6, Color(1, 1, 1, 0.25 + 0.2 * pulse))
	if _in_metro():
		_draw_escalator(true)


func _in_metro() -> bool:
	return World.current != null and World.current.dungeon != null and World.current.dungeon.is_metro()


## Nella metro le porte delle scale sono scale mobili ferme: gradini con i
## corrimano di gomma nera; quella verso il piano sotto ha sopra una
## lampada d'emergenza rossa che sfarfalla, quella verso l'aperto il
## cartello con la M.
func _draw_escalator(up: bool) -> void:
	var width := radius * 1.0
	var height := radius * 2.0
	var steps := PackedVector2Array()
	for k in 6:
		var y := -2.0 - k * (height * 0.8 / 6.0)
		var w := width * (0.85 - k * 0.08)
		steps.append_array([_edge * -w + Vector2(0, y), _edge * w + Vector2(0, y)])
	draw_multiline(steps, Color(0.25, 0.25, 0.27) if not up else Color(0.55, 0.52, 0.45, 0.8), 2.0)
	for side: float in [-1.0, 1.0]:
		draw_line(_edge * side * width * 0.95, _edge * side * width * 0.5 + Vector2(0, -height * 0.85), Color(0.05, 0.05, 0.05), 4.0)
	var lamp := Vector2(0, -height - 16.0)
	if up:
		draw_rect(Rect2(lamp - Vector2(8, 8), Vector2(16, 16)), _type_color_or("sign", Color(0.75, 0.15, 0.12)))
		draw_polyline(PackedVector2Array([lamp + Vector2(-4, 4), lamp + Vector2(-4, -4), lamp + Vector2(0, 1), lamp + Vector2(4, -4), lamp + Vector2(4, 4)]), Color(0.95, 0.95, 0.9), 2.0)
		return
	# Sfarfalla in modo irregolare, come un neon che sta per morire.
	var t := Time.get_ticks_msec() / 1000.0
	var flicker := 1.0 if sin(t * 13.0) + sin(t * 7.3) > -0.6 else 0.15
	draw_circle(lamp, 14.0, Color(1.0, 0.15, 0.1, 0.18 * flicker))
	draw_circle(lamp, 5.0, Color(1.0, 0.25, 0.2, 0.9 * flicker + 0.1))


func _type_color_or(key: String, fallback: Color) -> Color:
	return _type_color(key) if _type.has(key) else fallback
