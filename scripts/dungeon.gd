class_name Dungeon
extends RefCounted
## Interno di un edificio abbandonato (nel codice "sotterraneo"): ogni
## piano è diviso a caso in stanze di misure diverse (uffici, corridoi
## lunghi e stretti, saloni), tagliando lo spazio più volte con muri dritti
## che si incontrano a T e a croce; ogni muro ha almeno una porta (a volte
## due, a volte manca del tutto e due stanze formano un salone) e nei saloni
## più grandi ci sono pilastri. Generato a caso ma sempre uguale per lo
## stesso edificio e lo stesso piano. Si arriva davanti a un
## passaggio nella parete che riporta in superficie e si cerca quello che
## scende al piano sotto (i passaggi sono sempre in una parete, mai a terra);
## all'ultimo piano, nella zona più lontana, c'è l'arena del boss: un
## salone quadrato largo il doppio di "arena_radius" rombi.
## Parametri in data/world.json ("dungeon").
##
## Il terreno lo disegna World come la superficie: il pavimento è al
## livello 0, la roccia è un blocco alto che non si scala.
##
## La metropolitana (kind "metro", parametri in "metro" di data/world.json)
## è un sotterraneo come gli altri, con la pianta di una stazione: al
## centro le banchine (due laterali e una a isola con i pilastri) tra due
## binari incassati un livello più in basso (TRACK), che continuano nelle
## gallerie buie oltre le banchine; sui binari i vagoni abbandonati (TRAIN,
## blocchi alti che non si scalano). Sopra e sotto la stazione i locali di
## servizio, divisi a caso in stanze come gli edifici, con le porte sulle
## banchine.

const DATA := preload("res://data/world.json")
## Ostacoli e nemici stanno ad almeno questa distanza (in rombi) da scale e arena.
const KEEP_CLEAR := 3
## Due passaggi nelle pareti non stanno mai più vicini di così (in rombi).
const PASSAGE_SPACING := 8

## Tipo di ogni rombo (solo grafica e altezze; vedi tile_at).
enum Tile { FLOOR, WALL, TRACK, TRAIN }

## Piano (1 = il primo sotto la superficie) e quanti piani ha il sotterraneo.
var depth := 1
var levels := 2
## "building" (edificio abbandonato) o "metro" (stazione della metropolitana).
var kind := "building"
var width := 0
var height := 0
var seed_value := 0
var wall_level := 4
## Stanze: {"center": Vector2i, "radius": int, "rect": Rect2i}; la prima è
## quella d'arrivo.
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

## Livello dei binari e della cima dei vagoni (solo nella metro).
var track_level := -1
var train_level := 2
## Rombi delle banchine: righe (v) e colonne (u) in cui c'è la stazione (solo nella metro).
var station_rows := Vector2i(-1, -1)

## 1 = pavimento, 0 = roccia; fuori dalla griglia è tutta roccia.
var _floor := PackedByteArray()
## Tipo di rombo (Tile), solo nella metro.
var _tiles := PackedByteArray()


func _init(dungeon_seed: int, depth_value: int, levels_value: int, kind_value := "building") -> void:
	seed_value = dungeon_seed
	depth = depth_value
	levels = levels_value
	kind = kind_value
	_generate()


## Parametri del tipo di sotterraneo ("dungeon" o "metro" di data/world.json).
static func data_for(kind_value: String) -> Dictionary:
	return DATA.data["metro" if kind_value == "metro" else "dungeon"]


func settings() -> Dictionary:
	return data_for(kind)


func is_metro() -> bool:
	return kind == "metro"


## Quanti piani ha il sotterraneo di una caverna (sempre lo stesso per la stessa caverna).
static func levels_for(cave_seed: int, kind_value := "building") -> int:
	var range_values: Array = data_for(kind_value)["levels"]
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


## Tipo del rombo (vedi Tile): negli edifici solo pavimento e muro.
func tile_at(cell: Vector2i) -> int:
	if not is_floor(cell):
		if is_metro() and cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height \
				and _tiles[cell.y * width + cell.x] == Tile.TRAIN:
			return Tile.TRAIN
		return Tile.WALL
	if is_metro():
		return _tiles[cell.y * width + cell.x]
	return Tile.FLOOR


## Livello del rombo: pavimento 0, muri wall_level, binari e vagoni i loro.
func level_at(cell: Vector2i) -> int:
	match tile_at(cell):
		Tile.TRACK:
			return track_level
		Tile.TRAIN:
			return train_level
		Tile.WALL:
			return wall_level
	return 0


## Pavimento libero tutto attorno e lontano da scale, arena e casse: qui
## si possono mettere stalagmiti e nemici senza chiudere le gallerie. Con
## loose basta il rombo stesso (i binari nelle gallerie sono stretti).
func is_open(cell: Vector2i, loose := false) -> bool:
	for i in range(-1, 2):
		for j in range(-1, 2):
			if not is_floor(cell + Vector2i(i, j)) and not (loose and (i != 0 or j != 0)):
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


## Rombi del pavimento di una stanza, per farci comparire i nemici.
func room_cells(room: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var center: Vector2i = room["center"]
	var radius: int = room["radius"]
	var rect: Rect2i = room.get("rect", Rect2i(center - Vector2i(radius, radius), Vector2i(radius, radius) * 2 + Vector2i.ONE))
	var loose := is_metro()
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var cell := Vector2i(x, y)
			if is_open(cell, loose):
				result.append(cell)
	return result


func _generate() -> void:
	var data := settings()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var size: Array = data["size"]
	width = int(size[0]) + int(size[1]) * (depth - 1)
	height = width
	wall_level = data["wall_level"]
	arena_radius = data["arena_radius"]
	_floor.resize(width * height)
	_floor.fill(0)
	var leaves: Array[Rect2i] = []
	var start_leaf: Rect2i
	if is_metro():
		start_leaf = _generate_station(rng, data, leaves)
	else:
		_generate_rooms(Rect2i(1, 1, width - 2, height - 2), rng, data, leaves)
		start_leaf = leaves[rng.randi() % leaves.size()]
	_place_passages(start_leaf, leaves, rng, data)


## Divide il rettangolo in stanze (aggiunte a leaves) con muri dritti e porte.
func _generate_rooms(area: Rect2i, rng: RandomNumberGenerator, data: Dictionary, leaves: Array[Rect2i]) -> void:
	# Lo spazio si taglia più volte con muri dritti: le stanze sono i pezzi
	# rimasti, i muri si incontrano a T e a croce.
	var first := leaves.size()
	var walls: Array[Dictionary] = []
	_split(area, rng, leaves, walls, data)
	for k in range(first, leaves.size()):
		_fill(leaves[k].position, leaves[k].end - Vector2i.ONE)
	# Ogni muro ha una porta (così tutte le stanze sono collegate), a volte
	# due, a volte sparisce del tutto (un salone); nei saloni grandi i pilastri.
	for wall in walls:
		if rng.randf() < float(data["merge_chance"]) and wall["cells"].size() <= int(data["merge_max"]):
			for cell: Vector2i in wall["cells"]:
				_set_floor(cell)
			continue
		_open_door(wall, rng)
		if rng.randf() < float(data["extra_doors"]):
			_open_door(wall, rng)
	for k in range(first, leaves.size()):
		_add_pillars(leaves[k], rng, data)


## Pianta della stazione della metro (vedi in cima): banchine, binari,
## gallerie, vagoni e locali di servizio. Le stanze per i nemici (leaves)
## sono i locali, pezzi di banchina e tratti di galleria; restituisce il
## pezzo di banchina d'arrivo, in fondo a sinistra della prima banchina.
func _generate_station(rng: RandomNumberGenerator, data: Dictionary, leaves: Array[Rect2i]) -> Rect2i:
	_tiles.resize(width * height)
	_tiles.fill(Tile.WALL)
	track_level = data["track_level"]
	train_level = data["train_level"]
	var side := int(data["side_platform"])
	var track := int(data["track_width"])
	var island_range: Array = data["island_platform"]
	var island := rng.randi_range(island_range[0], island_range[1])
	var total := side * 2 + track * 2 + island
	var top := (height - total) / 2 + rng.randi_range(-2, 2)
	station_rows = Vector2i(top, top + total - 1)
	var ends: Array = data["platform_end"]
	var x0 := 1 + rng.randi_range(ends[0], ends[1])
	var x1 := width - 2 - rng.randi_range(ends[0], ends[1])
	# Righe dall'alto: banchina, binario, isola, binario, banchina.
	var rows: Array[Array] = []
	var y := top
	for part: Array in [["side", side], ["track", track], ["island", island], ["track", track], ["side", side]]:
		rows.append([part[0], y, y + int(part[1]) - 1])
		y += int(part[1])
	var segment := int(data["platform_segment"])
	for row: Array in rows:
		var first: int = row[1]
		var last: int = row[2]
		if row[0] == "track":
			# I binari attraversano tutta la pianta: oltre le banchine sono gallerie.
			for x in range(1, width - 1):
				for v in range(first, last + 1):
					_set_tile(Vector2i(x, v), Tile.TRACK)
			for start: int in [1, x1 + 1]:
				var end := x0 - 1 if start == 1 else width - 2
				if end - start >= 3:
					leaves.append(Rect2i(start, first, end - start + 1, last - first + 1))
			continue
		_fill(Vector2i(x0, first), Vector2i(x1, last))
		var x := x0
		while x <= x1:
			var length := mini(segment, x1 - x + 1)
			leaves.append(Rect2i(x, first, length, last - first + 1))
			x += length
	# Pilastri in mezzo alla banchina a isola, uno ogni "pillar_step" rombi.
	var island_row: Array = rows[2]
	var middle := (int(island_row[1]) + int(island_row[2])) / 2
	for x in range(x0 + 2, x1 - 1, int(data["pillar_step"])):
		_floor[middle * width + x] = 0
		_set_tile(Vector2i(x, middle), Tile.WALL, false)
	# Vagoni abbandonati sui binari, solo lungo le banchine (così non
	# chiudono le gallerie): blocchi lunghi con un rombo libero tra l'uno e l'altro.
	var cars: Array = data["train_cars"]
	var car_length: Array = data["car_length"]
	for row: Array in [rows[1], rows[3]]:
		if rng.randf() >= float(data["train_chance"]):
			continue
		var count := rng.randi_range(cars[0], cars[1])
		var x := rng.randi_range(x0 + 1, maxi(x0 + 1, x1 - 1 - count * (int(car_length[1]) + 1)))
		for k in count:
			var length := rng.randi_range(car_length[0], car_length[1])
			for i in mini(length, x1 - x):
				for v in range(int(row[1]), int(row[2]) + 1):
					_floor[v * width + x + i] = 0
					_set_tile(Vector2i(x + i, v), Tile.TRAIN, false)
			x += length + 1
	# Locali di servizio sopra e sotto la stazione, con le porte sulle banchine.
	var areas := [Rect2i(1, 1, width - 2, top - 2), Rect2i(1, station_rows.y + 2, width - 2, height - station_rows.y - 3)]
	for k in areas.size():
		var area: Rect2i = areas[k]
		if area.size.y < int(data["room_size"][0]):
			continue
		_generate_rooms(area, rng, data, leaves)
		var wall_y := top - 1 if k == 0 else station_rows.y + 1
		var cells: Array[Vector2i] = []
		for x in range(x0, x1 + 1):
			cells.append(Vector2i(x, wall_y))
		var wall := {"cells": cells, "across": Vector2i(0, 1)}
		for _door in int(data["service_doors"]):
			_open_door(wall, rng)
	# Ciò che non si raggiunge dalla banchina d'arrivo diventa muro.
	var start := Rect2i(x0, top, mini(segment, x1 - x0 + 1), side)
	var reached := _distances_from(_center(start))
	for v in height:
		for x in width:
			var cell := Vector2i(x, v)
			if is_floor(cell) and not reached.has(cell):
				_floor[v * width + x] = 0
				_tiles[v * width + x] = Tile.WALL
	return start


## Arrivo, scala (o arena del boss all'ultimo piano), stanze e casse.
func _place_passages(start_leaf: Rect2i, leaves: Array[Rect2i], rng: RandomNumberGenerator, data: Dictionary) -> void:
	# La stanza più lontana a piedi ha la scala, o l'arena del boss.
	var arrival_room := _center(start_leaf)
	var arrival_spot := _wall_spot(arrival_room, maxi(start_leaf.size.x, start_leaf.size.y) / 2 + 2)
	arrival = arrival_spot[0]
	arrival_side = arrival_spot[1]
	var distances := _distances_from(arrival)
	var far := start_leaf
	for leaf in leaves:
		if distances.get(_center(leaf), 0) > distances.get(_center(far), 0) and is_floor(_center(leaf)):
			far = leaf
	if is_last():
		# Arena: un salone quadrato attorno alla stanza più lontana, dentro la pianta.
		var low := arena_radius + 2
		var high := width - arena_radius - 3
		arena = _center(far).clamp(Vector2i(low, low), Vector2i(high, high))
		if arena.distance_to(arrival) < arena_radius + 4:
			arena = Vector2i(width - 1, height - 1) - arena
			arena = arena.clamp(Vector2i(low, low), Vector2i(high, high))
		_fill(arena - Vector2i(arena_radius, arena_radius), arena + Vector2i(arena_radius, arena_radius))
	var arena_rect := Rect2i(arena - Vector2i(arena_radius + 1, arena_radius + 1), Vector2i(arena_radius, arena_radius) * 2 + Vector2i(3, 3))
	rooms = [_room(start_leaf, false)]
	var others: Array[Dictionary] = []
	for leaf in leaves:
		if leaf == start_leaf or (is_last() and arena_rect.intersects(leaf)):
			continue
		var room := _room(leaf, leaf == far)
		others.append(room)
	rooms.append_array(others)
	if is_last():
		rooms.append({"center": arena, "radius": arena_radius})
		var exit_spot := _wall_spot(arena, arena_radius + 2, [arrival])
		arena_exit = exit_spot[0]
		arena_exit_side = exit_spot[1]
	else:
		var stairs_spot := _wall_spot(_center(far), maxi(far.size.x, far.size.y) / 2 + 2, [arrival])
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


## Taglia il rettangolo con un muro dritto (lungo il lato più lungo, in un
## punto a caso) e poi i due pezzi, finché sono abbastanza piccoli: i pezzi
## finali sono le stanze (leaves), i muri si ricordano in walls con i loro
## rombi. Più o meno a caso restano anche stanze grandi (saloni) e strette
## (corridoi).
func _split(rect: Rect2i, rng: RandomNumberGenerator, leaves: Array[Rect2i], walls: Array[Dictionary], data: Dictionary) -> void:
	var room: Array = data["room_size"]
	var smallest := int(room[0])
	var largest := int(room[1])
	var can_x := rect.size.x >= 2 * smallest + 1
	var can_y := rect.size.y >= 2 * smallest + 1
	var fits := rect.size.x <= largest and rect.size.y <= largest
	if not (can_x or can_y) or (fits and rng.randf() < float(data["stop_chance"])):
		leaves.append(rect)
		return
	var along_x := can_x and (not can_y or rect.size.x > rect.size.y or (rect.size.x == rect.size.y and rng.randf() < 0.5))
	var length := rect.size.x if along_x else rect.size.y
	# A volte un corridoio stretto lungo il muro.
	var cut := rng.randi_range(smallest, length - smallest - 1)
	if rng.randf() < float(data["corridor_chance"]) and length >= 2 * smallest + 4:
		cut = 2 if rng.randf() < 0.5 else length - 3
	var cells: Array[Vector2i] = []
	if along_x:
		for y in range(rect.position.y, rect.end.y):
			cells.append(Vector2i(rect.position.x + cut, y))
		_split(Rect2i(rect.position, Vector2i(cut, rect.size.y)), rng, leaves, walls, data)
		_split(Rect2i(rect.position + Vector2i(cut + 1, 0), Vector2i(rect.size.x - cut - 1, rect.size.y)), rng, leaves, walls, data)
	else:
		for x in range(rect.position.x, rect.end.x):
			cells.append(Vector2i(x, rect.position.y + cut))
		_split(Rect2i(rect.position, Vector2i(rect.size.x, cut)), rng, leaves, walls, data)
		_split(Rect2i(rect.position + Vector2i(0, cut + 1), Vector2i(rect.size.x, rect.size.y - cut - 1)), rng, leaves, walls, data)
	walls.append({"cells": cells, "across": Vector2i(1, 0) if along_x else Vector2i(0, 1)})


## Porta larga due rombi nel muro, dove da tutte e due le parti c'è
## pavimento (non contro un altro muro che arriva a T).
func _open_door(wall: Dictionary, rng: RandomNumberGenerator) -> void:
	var cells: Array = wall["cells"]
	var across: Vector2i = wall["across"]
	var options: Array[int] = []
	for k in cells.size() - 1:
		var ok := true
		for cell: Vector2i in [cells[k], cells[k + 1]]:
			if not is_floor(cell + across) or not is_floor(cell - across):
				ok = false
		if ok:
			options.append(k)
	if options.is_empty():
		# Muro corto o tutto contro altri muri: basta un rombo dove si passa.
		for k in cells.size():
			if is_floor(cells[k] + across) and is_floor(cells[k] - across):
				options.append(k)
		if options.is_empty():
			return
		_set_floor(cells[options[rng.randi() % options.size()]])
		return
	var at := options[rng.randi() % options.size()]
	_set_floor(cells[at])
	_set_floor(cells[at + 1])


## Pilastri nei saloni più grandi: un rombo di muro ogni tre, lontano dai muri.
func _add_pillars(leaf: Rect2i, rng: RandomNumberGenerator, data: Dictionary) -> void:
	if leaf.size.x < int(data["pillar_room"]) or leaf.size.y < int(data["pillar_room"]) or rng.randf() >= float(data["pillar_chance"]):
		return
	for x in range(leaf.position.x + 2, leaf.end.x - 2, 3):
		for y in range(leaf.position.y + 2, leaf.end.y - 2, 3):
			_floor[y * width + x] = 0


static func _center(rect: Rect2i) -> Vector2i:
	return rect.position + rect.size / 2


func _room(rect: Rect2i, far: bool) -> Dictionary:
	return {"center": _center(rect), "radius": maxi(mini(rect.size.x, rect.size.y) / 2 - 1, 0), "rect": rect, "far": far}


## Pavimento in tutto il rettangolo da first a last (compresi).
func _fill(first: Vector2i, last: Vector2i) -> void:
	for x in range(first.x, last.x + 1):
		for y in range(first.y, last.y + 1):
			_set_floor(Vector2i(x, y))


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
		if is_metro():
			_tiles[cell.y * width + cell.x] = Tile.FLOOR


## Tipo di un rombo della metro; floor: è anche pavimento (i binari sì, muri e vagoni no).
func _set_tile(cell: Vector2i, tile: int, floor := true) -> void:
	if cell.x >= 1 and cell.y >= 1 and cell.x < width - 1 and cell.y < height - 1:
		if floor:
			_floor[cell.y * width + cell.x] = 1
		_tiles[cell.y * width + cell.x] = tile


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
