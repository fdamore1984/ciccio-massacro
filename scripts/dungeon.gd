class_name Dungeon
extends RefCounted
## Interno di un edificio abbandonato (nel codice "sotterraneo"): ogni
## piano è una pianta regolare di stanze quadrate su una griglia, separate
## da muri dritti con porte larghe due rombi (a volte il muro manca e due
## stanze formano un salone), generata a caso ma sempre uguale per lo
## stesso edificio e lo stesso piano. Si arriva davanti a un
## passaggio nella parete che riporta in superficie e si cerca quello che
## scende al piano sotto (i passaggi sono sempre in una parete, mai a terra);
## all'ultimo piano, nella zona più lontana, c'è l'arena del boss: un
## salone di 2 × 2 stanze.
## Parametri in data/world.json ("dungeon").
##
## Il terreno lo disegna World come la superficie: il pavimento è al
## livello 0, la roccia è un blocco alto che non si scala.

const DATA := preload("res://data/world.json")
## Ostacoli e nemici stanno ad almeno questa distanza (in rombi) da scale e arena.
const KEEP_CLEAR := 3
## Due passaggi nelle pareti non stanno mai più vicini di così (in rombi).
const PASSAGE_SPACING := 8

## Piano (1 = il primo sotto la superficie) e quanti piani ha il sotterraneo.
var depth := 1
var levels := 2
var width := 0
var height := 0
var seed_value := 0
var wall_level := 4
## Stanze: {"center": Vector2i, "radius": int}; la prima è quella d'arrivo.
var rooms: Array[Dictionary] = []
var arrival := Vector2i.ZERO
## Lato del rombo in cui si apre il passaggio nella parete (vedi _wall_spot).
var arrival_side := Vector2i(-1, 0)
## Scala per scendere (solo se non è l'ultimo piano) e arena del boss (solo all'ultimo).
var stairs := Vector2i(-1, -1)
var stairs_side := Vector2i(-1, 0)
var arena := Vector2i(-1, -1)
## Dove si apre l'uscita dopo il boss, nella parete dell'arena.
var arena_exit := Vector2i(-1, -1)
var arena_exit_side := Vector2i(-1, 0)
var arena_radius := 0
var chests: Array[Vector2i] = []
## Casse già aperte in questo piano (posizione -> true).
var opened_chests := {}

## 1 = pavimento, 0 = roccia; fuori dalla griglia è tutta roccia.
var _floor := PackedByteArray()


func _init(dungeon_seed: int, depth_value: int, levels_value: int) -> void:
	seed_value = dungeon_seed
	depth = depth_value
	levels = levels_value
	_generate()


## Quanti piani ha il sotterraneo di una caverna (sempre lo stesso per la stessa caverna).
static func levels_for(cave_seed: int) -> int:
	var range_values: Array = DATA.data["dungeon"]["levels"]
	var rng := RandomNumberGenerator.new()
	rng.seed = cave_seed
	return rng.randi_range(range_values[0], range_values[1])


func is_last() -> bool:
	return depth >= levels


## Centro dell'arena del boss nel mondo (solo all'ultimo piano).
func arena_center() -> Vector2:
	return World.cell_center(arena)


func is_floor(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return false
	return _floor[cell.y * width + cell.x] == 1


## Pavimento libero tutto attorno e lontano da scale, arena e casse: qui
## si possono mettere stalagmiti e nemici senza chiudere le gallerie.
func is_open(cell: Vector2i) -> bool:
	for i in range(-1, 2):
		for j in range(-1, 2):
			if not is_floor(cell + Vector2i(i, j)):
				return false
	for spot in [arrival, stairs]:
		if spot.x >= 0 and (spot as Vector2i).distance_to(cell) < KEEP_CLEAR:
			return false
	if arena.x >= 0 and arena.distance_to(cell) < arena_radius + 1:
		return false
	for chest in chests:
		if chest.distance_to(cell) < 2:
			return false
	return true


## Pezzi di mondo (vedi World) che coprono il sotterraneo, con un bordo di roccia.
func chunk_rect() -> Rect2i:
	var last := Vector2i(floori(float(width) / World.CHUNK_CELLS), floori(float(height) / World.CHUNK_CELLS))
	return Rect2i(Vector2i(-1, -1), last + Vector2i(3, 3))


## Rombi del pavimento di una caverna, per farci comparire i nemici.
func room_cells(room: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var center: Vector2i = room["center"]
	var radius: int = room["radius"]
	for i in range(-radius, radius + 1):
		for j in range(-radius, radius + 1):
			var cell := center + Vector2i(i, j)
			if is_open(cell):
				result.append(cell)
	return result


func _generate() -> void:
	var data: Dictionary = DATA.data["dungeon"]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var size: Array = data["size"]
	width = int(size[0]) + int(size[1]) * (depth - 1)
	height = width
	wall_level = data["wall_level"]
	arena_radius = data["arena_radius"]
	_floor.resize(width * height)
	_floor.fill(0)
	# Griglia di stanze: ognuna ha room_size rombi di lato, con un muro di un
	# rombo tra una e l'altra.
	var pitch := int(data["room_size"]) + 1
	var count := maxi((width - 1) / pitch, 2)
	for i in count:
		for j in count:
			_fill(Vector2i(i * pitch + 1, j * pitch + 1), Vector2i(i * pitch + pitch - 1, j * pitch + pitch - 1))
	# Collegamenti: un albero che tocca tutte le stanze (porte o muri
	# abbattuti), più qualche porta in più per fare dei giri.
	var linked := {}
	var stack: Array[Vector2i] = [Vector2i(rng.randi() % count, rng.randi() % count)]
	var visited := {stack[0]: true}
	var steps: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not stack.is_empty():
		var room: Vector2i = stack.back()
		var options: Array[Vector2i] = []
		for step in steps:
			var next := room + step
			if next.x >= 0 and next.y >= 0 and next.x < count and next.y < count and not visited.has(next):
				options.append(next)
		if options.is_empty():
			stack.pop_back()
			continue
		var next := options[rng.randi() % options.size()]
		visited[next] = true
		_open_wall(room, next, pitch, rng.randf() < float(data["merge_chance"]))
		linked[[room, next]] = true
		linked[[next, room]] = true
		stack.append(next)
	for i in count:
		for j in count:
			for step: Vector2i in [Vector2i(1, 0), Vector2i(0, 1)]:
				var room := Vector2i(i, j)
				var next := room + step
				if next.x < count and next.y < count and not linked.has([room, next]) and rng.randf() < float(data["extra_doors"]):
					_open_wall(room, next, pitch, false)
	# Stanza d'arrivo a caso; la più lontana a piedi ha la scala, o l'arena del boss.
	var start := Vector2i(rng.randi() % count, rng.randi() % count)
	var half := pitch / 2
	var arrival_room := start * pitch + Vector2i(half, half)
	var arrival_spot := _wall_spot(arrival_room, half + 2)
	arrival = arrival_spot[0]
	arrival_side = arrival_spot[1]
	var distances := _distances_from(arrival)
	var far := start
	for i in count:
		for j in count:
			if distances.get(Vector2i(i, j) * pitch + Vector2i(half, half), 0) > distances.get(far * pitch + Vector2i(half, half), 0):
				far = Vector2i(i, j)
	# Arena: il salone di 2 × 2 stanze che contiene quella più lontana (senza
	# quella d'arrivo).
	var arena_block := Rect2i()
	if is_last():
		for a in [Vector2i(mini(far.x, count - 2), mini(far.y, count - 2)), Vector2i(maxi(far.x - 1, 0), maxi(far.y - 1, 0)),
				Vector2i(mini(far.x, count - 2), maxi(far.y - 1, 0)), Vector2i(maxi(far.x - 1, 0), mini(far.y, count - 2))]:
			arena_block = Rect2i(a, Vector2i(2, 2))
			if not arena_block.has_point(start):
				break
		_fill(arena_block.position * pitch + Vector2i(1, 1), arena_block.end * pitch - Vector2i(1, 1))
		arena = arena_block.position * pitch + Vector2i(pitch, pitch)
	rooms = [{"center": arrival_room, "radius": half - 1}]
	var others: Array[Dictionary] = []
	for i in count:
		for j in count:
			var room := Vector2i(i, j)
			if room != start and not (is_last() and arena_block.has_point(room)):
				others.append({"center": room * pitch + Vector2i(half, half), "radius": half - 1, "far": room == far})
	rooms.append_array(others)
	if is_last():
		rooms.append({"center": arena, "radius": arena_radius})
		var exit_spot := _wall_spot(arena, arena_radius + 2, [arrival])
		arena_exit = exit_spot[0]
		arena_exit_side = exit_spot[1]
	else:
		var stairs_spot := _wall_spot(far * pitch + Vector2i(half, half), half + 2, [arrival])
		stairs = stairs_spot[0]
		stairs_side = stairs_spot[1]
	# Casse nelle altre stanze.
	var chest_range: Array = data["chests"]
	var candidates: Array[Dictionary] = []
	for room in others:
		if not room["far"]:
			candidates.append(room)
	for k in mini(rng.randi_range(chest_range[0], chest_range[1]), candidates.size()):
		var room: Dictionary = candidates.pop_at(rng.randi() % candidates.size())
		var spot: Vector2i = room["center"] + Vector2i(rng.randi_range(-1, 1), rng.randi_range(-1, 1))
		if is_floor(spot):
			chests.append(spot)


## Pavimento in tutto il rettangolo da first a last (compresi).
func _fill(first: Vector2i, last: Vector2i) -> void:
	for x in range(first.x, last.x + 1):
		for y in range(first.y, last.y + 1):
			_set_floor(Vector2i(x, y))


## Apre il muro tra due stanze vicine della griglia: tutto (merge, un
## salone) o una porta larga due rombi nel mezzo.
func _open_wall(a: Vector2i, b: Vector2i, pitch: int, merge: bool) -> void:
	var low := Vector2i(mini(a.x, b.x), mini(a.y, b.y))
	var wall := (low + (b - a).abs()) * pitch
	var along := Vector2i(0, 1) if a.x != b.x else Vector2i(1, 0)
	var first := 1 if merge else pitch / 2 - 1
	var last := pitch - 1 if merge else pitch / 2
	for k in range(first, last + 1):
		_set_floor(wall + along * k)


## Passaggio in una parete vicino al punto: un rombo di pavimento con
## dietro (lato in alto a sinistra o in alto a destra sullo schermo) un
## tratto dritto di roccia e attorno pavimento libero, così l'arco si vede
## bene, lontano dai passaggi in avoid. Restituisce [rombo, lato]; se non
## c'è si accontenta di un rombo con la roccia dietro, poi cerca ovunque.
func _wall_spot(near: Vector2i, max_distance: int, avoid: Array[Vector2i] = []) -> Array:
	for reach: int in [max_distance, maxi(width, height)]:
		for strict: bool in [true, false]:
			var spot := _find_wall_spot(near, reach, avoid, strict)
			if not spot.is_empty():
				return spot
	return [near, Vector2i(-1, 0)]


func _find_wall_spot(near: Vector2i, max_distance: int, avoid: Array[Vector2i], strict: bool) -> Array:
	var best: Array = []
	var best_distance := INF
	for i in range(-max_distance, max_distance + 1):
		for j in range(-max_distance, max_distance + 1):
			var cell := near + Vector2i(i, j)
			if not is_floor(cell) or (strict and not is_floor(cell + Vector2i(1, 1))):
				continue
			if avoid.any(func(other: Vector2i) -> bool: return other.distance_to(cell) < PASSAGE_SPACING):
				continue
			for side: Vector2i in [Vector2i(-1, 0), Vector2i(0, -1)]:
				var along := Vector2i(side.y, side.x)
				if is_floor(cell + side) or not is_floor(cell - side):
					continue
				if strict and (is_floor(cell + side + along) or is_floor(cell + side - along) \
						or not is_floor(cell + along) or not is_floor(cell - along)):
					continue
				var distance := Vector2(i, j).length()
				if distance < best_distance:
					best = [cell, side]
					best_distance = distance
	return best


func _set_floor(cell: Vector2i) -> void:
	if cell.x >= 1 and cell.y >= 1 and cell.x < width - 1 and cell.y < height - 1:
		_floor[cell.y * width + cell.x] = 1


## Distanza a piedi (in rombi) di ogni rombo del pavimento dal punto.
func _distances_from(start: Vector2i) -> Dictionary:
	var distances := {start: 0}
	var queue: Array[Vector2i] = [start]
	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next := cell + step
			if is_floor(next) and not distances.has(next):
				distances[next] = distances[cell] + 1
				queue.append(next)
	return distances
