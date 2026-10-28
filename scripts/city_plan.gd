class_name CityPlan
extends RefCounted
## Pianta della città in rovina (voce "city" di data/world.json), sempre
## uguale per lo stesso seme. World la usa per sapere cosa c'è su ogni rombo
## della superficie (vedi code).
##
## Le strade non sono una griglia regolare: lungo ognuno dei due assi il
## mondo è diviso in fasce di larghezza diversa (isolati da "block" rombi)
## separate da strade larghe da 1 a 3 rombi ("roads": vicoli, strade e viali
## alberati, con lo spartitraffico e gli alberi secchi in mezzo). Alcuni
## tratti di vicoli e strade sono chiusi da un edificio o da un giardino
## ("closed_road_chance"): così ci sono vicoli ciechi e incroci a T.
## Ogni isolato ha il marciapiede attorno ed è diviso a caso in lotti di
## misure diverse ("lot_min", "lot_max"), a volte separati da vicoletti
## ("alley_chance"), a volte attaccati: case basse col cortile, file di
## negozi, uffici, condomini, grattacieli, parchi, parcheggi, piazzette con
## l'ingresso della metropolitana, cumuli di macerie ("lots"). Gli edifici
## sono in rovina: in parte crollati verso un angolo, col tetto spezzato e
## qualche pezzo di muro caduto. Nessun edificio è largo un rombo solo.
##
## Fasce e lotti si calcolano una volta e si ricordano.

## Cosa c'è su un rombo (vedi code). BUILDING: un edificio (alto
## height_of livelli, nello stile style_of); METRO: il rombo al centro di
## una piazzetta con l'ingresso della metropolitana; le altre sono a terra.
enum Zone { ROAD, ALLEY, MEDIAN, SIDEWALK, YARD, PARK, PARKING, PLAZA, RUBBLE, METRO, BUILDING }
## Nomi delle zone a terra (per colori e ostacoli in data/world.json).
const ZONE_NAMES := ["road", "alley", "median", "sidewalk", "yard", "park", "parking", "plaza", "rubble", "metro", "building"]

var seed_value := 0
var _data: Dictionary
## Nomi degli stili degli edifici, nell'ordine di "styles".
var styles: Array[String] = []
## [asse, segmento] -> fasce del segmento (Vector3i: inizio, lunghezza,
## larghezza della strada o 0 per un isolato).
var _strips := {}
## Isolato -> lotti (vedi _make_lot).
var _lots := {}


func _init(world_seed: int, data: Dictionary) -> void:
	seed_value = world_seed
	_data = data
	for style: String in data["styles"]:
		styles.append(style)


## Zona, altezza (livelli) e stile del rombo, in un intero (vedi zone_of,
## height_of, style_of).
func code(cell: Vector2i) -> int:
	var sx := _strip(cell.x, 0)
	var sy := _strip(cell.y, 1)
	var road_x := sx.w > 0
	var road_y := sy.w > 0
	if road_x and road_y:
		return Zone.ROAD
	if road_x or road_y:
		var road := sx if road_x else sy
		var other := sy if road_x else sx
		if road.w <= 2 and _closed(road.x, other.x):
			# Tratto chiuso: un piccolo isolato senza marciapiede.
			return _block_code(Vector2i(sx.x, sy.x), Vector2i(sx.y, sy.y), Vector2i(sx.z, sy.z), true)
		if road.w >= 3 and road.y == road.w / 2:
			return Zone.MEDIAN
		return Zone.ROAD
	return _block_code(Vector2i(sx.x, sy.x), Vector2i(sx.y, sy.y), Vector2i(sx.z, sy.z), false)


static func zone_of(value: int) -> int:
	return value & 15


static func height_of(value: int) -> int:
	return (value >> 4) & 15


static func style_of(value: int) -> int:
	return (value >> 8) & 15


static func _pack(zone: int, height := 0, style := 0) -> int:
	return zone | (height << 4) | (style << 8)


## La fascia dell'asse (0: x, 1: y) che contiene la coordinata: Vector4i con
## un numero che la distingue, la posizione dentro la fascia, la sua
## lunghezza e la larghezza della strada (0 se è un isolato).
func _strip(coord: int, axis: int) -> Vector4i:
	var size := int(_data["segment"])
	var segment := floori(float(coord) / size)
	var key := Vector2i(segment, axis)
	if not _strips.has(key):
		_strips[key] = _make_strips(segment, axis)
	var local := coord - segment * size
	var strips: Array = _strips[key]
	for k in strips.size():
		var strip: Vector3i = strips[k]
		if local < strip.x + strip.y:
			return Vector4i(segment * 64 + k, local - strip.x, strip.y, strip.z)
	return Vector4i(segment * 64, 0, 1, 0)


## Fasce di un segmento dell'asse: una strada all'inizio, poi isolati e
## strade alternati fino alla fine del segmento (l'ultimo isolato la riempie).
func _make_strips(segment: int, axis: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, segment, axis, "strips"])
	var size := int(_data["segment"])
	var block: Array = _data["block"]
	var strips: Array = []
	var at := 0
	while at < size:
		var road := _road_width(rng)
		strips.append(Vector3i(at, road, road))
		at += road
		var length := rng.randi_range(block[0], block[1])
		if at + length + 3 + int(block[0]) > size:
			length = size - at
		strips.append(Vector3i(at, length, 0))
		at += length
	return strips


func _road_width(rng: RandomNumberGenerator) -> int:
	var roads: Array = _data["roads"]
	var total := 0.0
	for road: Array in roads:
		total += float(road[1])
	var roll := rng.randf() * total
	for road: Array in roads:
		roll -= float(road[1])
		if roll <= 0.0:
			return int(road[0])
	return int(roads[0][0])


## Il tratto della strada road che attraversa l'isolato other è chiuso?
func _closed(road: int, other: int) -> bool:
	return _unit([road, other, "closed"]) < float(_data["closed_road_chance"])


## Rombo dentro un isolato (id: le due fasce, local: posizione, size:
## grandezza); closed: un tratto di strada chiuso, senza marciapiede.
func _block_code(id: Vector2i, local: Vector2i, size: Vector2i, closed: bool) -> int:
	var inner := local
	var inner_size := size
	if not closed:
		if local.x == 0 or local.y == 0 or local.x == size.x - 1 or local.y == size.y - 1:
			return Zone.SIDEWALK
		inner = local - Vector2i.ONE
		inner_size = size - Vector2i(2, 2)
	for lot: Dictionary in _lots_of(id, inner_size, closed):
		var rect: Rect2i = lot["rect"]
		if rect.has_point(inner):
			return _lot_code(lot, inner - rect.position)
	# Tra un lotto e l'altro corre un vicoletto.
	return Zone.ALLEY


func _lots_of(id: Vector2i, size: Vector2i, closed: bool) -> Array:
	var key := Vector3i(id.x, id.y, 1 if closed else 0)
	var cached: Variant = _lots.get(key)
	if cached != null:
		return cached
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, id.x, id.y, closed, "lots"])
	var lots: Array = []
	if size.x > 0 and size.y > 0:
		if closed:
			# Un vicolo chiuso largo un rombo non ha edifici (sarebbero larghi un rombo).
			var kinds := ["shop", "house", "rubble", "park"] if mini(size.x, size.y) >= 2 else ["rubble", "park"]
			lots.append(_make_lot(Rect2i(Vector2i.ZERO, size), rng, kinds))
		else:
			_split(Rect2i(Vector2i.ZERO, size), rng, lots)
	_lots[key] = lots
	return lots


## Divide il rettangolo in lotti, a caso: lungo il lato più lungo, a volte
## con un vicoletto in mezzo.
func _split(rect: Rect2i, rng: RandomNumberGenerator, out: Array) -> void:
	var lot_min := int(_data["lot_min"])
	var lot_max := int(_data["lot_max"])
	var can_x := rect.size.x >= 2 * lot_min
	var can_y := rect.size.y >= 2 * lot_min
	var small := rect.size.x <= lot_max and rect.size.y <= lot_max
	if not (can_x or can_y) or (small and rng.randf() < 0.45):
		out.append(_make_lot(rect, rng, []))
		return
	var along_x := can_x and (not can_y or rect.size.x >= rect.size.y)
	var length := rect.size.x if along_x else rect.size.y
	var alley := 1 if rng.randf() < float(_data["alley_chance"]) and length >= 2 * lot_min + 1 else 0
	var cut := rng.randi_range(lot_min, length - lot_min - alley)
	if along_x:
		_split(Rect2i(rect.position, Vector2i(cut, rect.size.y)), rng, out)
		_split(Rect2i(rect.position + Vector2i(cut + alley, 0), Vector2i(rect.size.x - cut - alley, rect.size.y)), rng, out)
	else:
		_split(Rect2i(rect.position, Vector2i(rect.size.x, cut)), rng, out)
		_split(Rect2i(rect.position + Vector2i(0, cut + alley), Vector2i(rect.size.x, rect.size.y - cut - alley)), rng, out)


## Sceglie cosa c'è nel lotto (tra only, se non è vuoto), pesato e secondo
## la grandezza, con altezza, stile, cortile e crollo.
func _make_lot(rect: Rect2i, rng: RandomNumberGenerator, only: Array) -> Dictionary:
	var kinds: Dictionary = _data["lots"]
	var side := mini(rect.size.x, rect.size.y)
	var weights := {}
	var total := 0.0
	for kind: String in kinds:
		var info: Dictionary = kinds[kind]
		if (not only.is_empty() and kind not in only) or side < int(info.get("min_size", 1)) \
				or side > int(info.get("max_size", 99)):
			continue
		weights[kind] = float(info["weight"])
		total += weights[kind]
	var chosen := "rubble"
	var roll := rng.randf() * total
	for kind: String in weights:
		roll -= weights[kind]
		if roll <= 0.0:
			chosen = kind
			break
	var info: Dictionary = kinds[chosen]
	var lot := {"rect": rect, "kind": chosen, "seed": rng.randi(), "height": 0, "style": 0, "inset": 0}
	if info.has("height"):
		var height: Array = info["height"]
		lot["height"] = rng.randi_range(height[0], height[1])
	if info.has("styles"):
		var names: Array = info["styles"]
		lot["style"] = styles.find(names[rng.randi() % names.size()])
	# Il cortile attorno resta solo se l'edificio è largo almeno due rombi.
	var inset := int(info.get("inset", 0))
	if side - 2 * inset >= 2:
		lot["inset"] = inset
	# Crollo verso un angolo: gli edifici si abbassano di più vicino all'angolo.
	if int(lot["height"]) > 1 and rng.randf() < float(_data["collapse_chance"]):
		lot["collapse"] = Vector2(rng.randi_range(0, 1) * rect.size.x, rng.randi_range(0, 1) * rect.size.y)
		lot["collapse_depth"] = rng.randi_range(1, int(lot["height"]) - 1)
	return lot


func _lot_code(lot: Dictionary, at: Vector2i) -> int:
	var rect: Rect2i = lot["rect"]
	var kind: String = lot["kind"]
	var info: Dictionary = _data["lots"][kind]
	match kind:
		"park":
			return Zone.PARK
		"parking":
			return Zone.PARKING
		"metro":
			return Zone.METRO if at == rect.size / 2 else Zone.PLAZA
		"rubble":
			# Cumuli di macerie a gruppi di due rombi per due, bassi.
			if _unit([lot["seed"], at.x / 2, at.y / 2, "heap"]) < float(info["heaps"]) and rect.size.x >= 2 and rect.size.y >= 2:
				return _pack(Zone.BUILDING, 1, styles.find("rubble"))
			return Zone.RUBBLE
	var inset: int = lot["inset"]
	if at.x < inset or at.y < inset or at.x >= rect.size.x - inset or at.y >= rect.size.y - inset:
		return Zone.YARD
	if not _built(lot, at):
		return Zone.RUBBLE
	# Un pezzo rimasto in piedi da solo crolla anche lui: niente edifici di un rombo.
	var alone := true
	for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if _built(lot, at + step):
			alone = false
			break
	if alone:
		return Zone.RUBBLE
	var height: int = lot["height"]
	if lot.has("collapse"):
		var reach := maxf(rect.size.x, rect.size.y) * 0.9
		var closeness := clampf(1.0 - (Vector2(at) + Vector2(0.5, 0.5)).distance_to(lot["collapse"]) / reach, 0.0, 1.0)
		height -= roundi(float(lot["collapse_depth"]) * closeness)
	if _unit([lot["seed"], at.x, at.y]) < float(_data["broken_top_chance"]):
		height -= 1
	return _pack(Zone.BUILDING, clampi(height, 1, 15), lot["style"])


## Il rombo at del lotto fa parte dell'edificio: dentro la pianta (senza il
## cortile) e non tra i pezzi di muro sul bordo crollati del tutto.
func _built(lot: Dictionary, at: Vector2i) -> bool:
	var rect: Rect2i = lot["rect"]
	var inset: int = lot["inset"]
	if at.x < inset or at.y < inset or at.x >= rect.size.x - inset or at.y >= rect.size.y - inset:
		return false
	var edge := at.x == inset or at.y == inset or at.x == rect.size.x - inset - 1 or at.y == rect.size.y - inset - 1
	return not (edge and _unit([lot["seed"], at.x, at.y, "missing"]) < float(_data["missing_cell_chance"]))


## Numero a caso tra 0 e 1, sempre uguale per gli stessi valori (e il seme).
func _unit(values: Array) -> float:
	return float(absi(hash([seed_value] + values)) % 100000) / 100000.0
