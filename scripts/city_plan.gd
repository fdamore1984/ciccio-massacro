class_name CityPlan
extends RefCounted
## Pianta della città in rovina (voce "city" di data/world.json), sempre
## uguale per lo stesso seme. World la usa per sapere cosa c'è su ogni rombo
## della superficie (vedi code).
##
## Non è una griglia regolare. I viali principali (larghi "avenues" rombi,
## con lo spartitraffico e gli alberi secchi in mezzo quando sono larghi 5)
## dividono la città in quartieri di misure diverse: quelli lungo y sono
## distanti in media "district" rombi, ognuno spostato a caso fino a
## "district_jitter"; quelli lungo x cambiano posto a ogni incrocio (fino
## a "avenue_jog" rombi), così gli incroci sono sfalsati, e a volte un tratto
## manca del tutto ("avenue_gap"): il viale finisce contro un quartiere,
## con un incrocio a T.
##
## Ogni quartiere è tagliato a caso da strade locali (larghe "streets" rombi,
## a volte vicoli larghi uno, "alley_chance") in isolati di misure diverse
## ("block"): le strade non continuano nel quartiere accanto (incroci a T) e
## alcune si fermano a metà ("dead_end_chance"), con i cortili dietro (vicoli
## ciechi). Qualche isolato è una piazza con un giardino dalla forma
## irregolare ("square_chance"). Ogni isolato ha il marciapiede attorno ed è
## diviso in lotti di misure diverse ("lot_min", "lot_max"), a volte
## separati da vicoletti ("lot_alley_chance"): case basse col cortile, file
## di negozi, uffici, condomini, grattacieli, parchi, parcheggi, piazzette
## con l'ingresso della metropolitana, cumuli di macerie ("lots"). Gli
## edifici più grandi a volte sono a L, con un cortile in un angolo
## ("notch_chance"); sono in rovina: in parte crollati verso un angolo, col
## tetto spezzato e qualche pezzo di muro caduto. Nessun edificio è largo
## un rombo solo.
##
## Le altezze degli edifici sono in piani: un piano è alto "storey_levels"
## livelli del terreno (vedi World.level_of), così i palazzi sono in
## proporzione con i personaggi.
##
## Quartieri e lotti si calcolano una volta e si ricordano.

## Cosa c'è su un rombo (vedi code). BUILDING: un edificio (alto
## height_of piani, nello stile style_of); METRO: il rombo al centro di
## una piazzetta con l'ingresso della metropolitana; le altre sono a terra.
enum Zone { ROAD, ALLEY, MEDIAN, SIDEWALK, YARD, PARK, PARKING, PLAZA, RUBBLE, METRO, BUILDING }
## Nomi delle zone a terra (per colori e ostacoli in data/world.json).
const ZONE_NAMES := ["road", "alley", "median", "sidewalk", "yard", "park", "parking", "plaza", "rubble", "metro", "building"]
## I viali larghi almeno così hanno lo spartitraffico in mezzo.
const MEDIAN_WIDTH := 5

var seed_value := 0
var _data: Dictionary
## Nomi degli stili degli edifici, nell'ordine di "styles".
var styles: Array[String] = []
## Quartiere (Vector2i: viale a sinistra, riga) -> pianta (vedi _make_district).
var _districts := {}


func _init(world_seed: int, data: Dictionary) -> void:
	seed_value = world_seed
	_data = data
	for style: String in data["styles"]:
		styles.append(style)


## Zona, altezza (piani) e stile del rombo, in un intero (vedi zone_of,
## height_of, style_of).
func code(cell: Vector2i) -> int:
	var row := _row_at(cell.y)
	if row.x == 1:
		# Viale lungo y: lo spartitraffico nel rombo di mezzo dei più larghi.
		return Zone.MEDIAN if row.w >= MEDIAN_WIDTH and row.z == row.w / 2 else Zone.ROAD
	var band := row.y
	var column := _column_at(cell.x, band)
	if column.x == 1:
		return Zone.MEDIAN if column.w >= MEDIAN_WIDTH and column.z == column.w / 2 else Zone.ROAD
	return _district_code(Vector2i(column.y, band), cell)


static func zone_of(value: int) -> int:
	return value & 15


static func height_of(value: int) -> int:
	return (value >> 4) & 15


static func style_of(value: int) -> int:
	return (value >> 8) & 15


static func _pack(zone: int, height := 0, style := 0) -> int:
	return zone | (height << 4) | (style << 8)


# --- Viali -------------------------------------------------------------

## Inizio del viale lungo y numero index (y del primo rombo).
func _row_avenue(index: int) -> int:
	var jitter := int(_data["district_jitter"])
	return index * int(_data["district"]) + roundi((_unit([index, "row"]) * 2.0 - 1.0) * jitter)


func _row_width(index: int) -> int:
	return _pick_width(_data["avenues"], _unit([index, "row_width"]))


## Riga di y: Vector4i(1 se è sul viale, numero del viale o della fascia
## di quartieri sotto di lui, posizione nel viale, larghezza del viale).
func _row_at(y: int) -> Vector4i:
	var first := floori(float(y) / int(_data["district"])) - 1
	for index in range(first, first + 3):
		var start := _row_avenue(index)
		var width := _row_width(index)
		if y >= start and y < start + width:
			return Vector4i(1, index, y - start, width)
		if y >= start + width and y < _row_avenue(index + 1):
			return Vector4i(0, index, 0, 0)
	return Vector4i(0, first, 0, 0)


## Inizio del viale lungo x numero index nella fascia band: si sposta a
## ogni incrocio (vedi in cima).
func _column_avenue(index: int, band: int) -> int:
	var jitter := int(_data["district_jitter"])
	var jog := int(_data["avenue_jog"])
	return index * int(_data["district"]) + roundi((_unit([index, "column"]) * 2.0 - 1.0) * jitter) \
			+ roundi((_unit([index, band, "jog"]) * 2.0 - 1.0) * jog)


func _column_width(index: int) -> int:
	return _pick_width(_data["avenues"], _unit([index, "column_width"]))


## Il tratto del viale index nella fascia band manca (solo per i viali
## dispari, così due quartieri accanto si uniscono al più a due a due).
func _column_gap(index: int, band: int) -> bool:
	return posmod(index, 2) == 1 and _unit([index, band, "gap"]) < float(_data["avenue_gap"])


## Colonna di x nella fascia band: Vector4i(1 se è sul viale, viale sul
## bordo sinistro del quartiere (o il viale stesso), posizione nel viale,
## larghezza).
func _column_at(x: int, band: int) -> Vector4i:
	var first := floori(float(x) / int(_data["district"])) - 1
	for index in range(first, first + 3):
		var start := _column_avenue(index, band)
		var width := _column_width(index)
		if x >= start and x < start + width:
			if _column_gap(index, band):
				return Vector4i(0, index - 1, 0, 0)
			return Vector4i(1, index, x - start, width)
		if x >= start + width and x < _column_avenue(index + 1, band):
			# Se il viale a sinistra manca il quartiere comincia da quello prima.
			return Vector4i(0, index - 1 if _column_gap(index, band) else index, 0, 0)
	return Vector4i(0, first, 0, 0)


## Rettangolo (in rombi del mondo) del quartiere con il viale left sul
## bordo sinistro, nella fascia band.
func _district_rect(left: int, band: int) -> Rect2i:
	var x0 := _column_avenue(left, band) + _column_width(left)
	var right := left + 1
	if _column_gap(right, band):
		right += 1
	var y0 := _row_avenue(band) + _row_width(band)
	return Rect2i(x0, y0, _column_avenue(right, band) - x0, _row_avenue(band + 1) - y0)


func _pick_width(widths: Array, roll: float) -> int:
	var total := 0.0
	for entry: Array in widths:
		total += float(entry[1])
	roll *= total
	for entry: Array in widths:
		roll -= float(entry[1])
		if roll <= 0.0:
			return int(entry[0])
	return int(widths[0][0])


# --- Quartieri ---------------------------------------------------------

## Rombo dentro un quartiere: strade locali, cortili dei vicoli ciechi,
## poi isolati (marciapiede, piazze, lotti).
func _district_code(id: Vector2i, cell: Vector2i) -> int:
	var district: Dictionary = _districts.get(id, {})
	if district.is_empty():
		district = _make_district(id)
		_districts[id] = district
	for street: Array in district["streets"]:
		if (street[0] as Rect2i).has_point(cell):
			return street[1]
	for block: Dictionary in district["blocks"]:
		var rect: Rect2i = block["rect"]
		if rect.has_point(cell):
			return _block_code(block, cell - rect.position)
	# Il resto (i rombi oltre la fine delle strade senza uscita) sono cortili.
	return Zone.YARD


## Taglia il quartiere in isolati con le strade locali (vedi in cima).
func _make_district(id: Vector2i) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed_value, id.x, id.y, "district"])
	var district := {"streets": [], "blocks": []}
	_cut(_district_rect(id.x, id.y), rng, district, 0)
	return district


func _cut(rect: Rect2i, rng: RandomNumberGenerator, district: Dictionary, depth: int) -> void:
	var block: Array = _data["block"]
	var smallest := int(block[0])
	var largest := int(block[1])
	var can_x := rect.size.x >= 2 * smallest + 2
	var can_y := rect.size.y >= 2 * smallest + 2
	var fits := rect.size.x <= largest and rect.size.y <= largest
	if not (can_x or can_y) or (fits and rng.randf() < 0.5) or depth > 8:
		district["blocks"].append(_make_block(rect, rng))
		return
	var along_x := can_x and (not can_y or rect.size.x > rect.size.y or (rect.size.x == rect.size.y and rng.randf() < 0.5))
	var length := rect.size.x if along_x else rect.size.y
	var across := rect.size.y if along_x else rect.size.x
	var width := 1 if rng.randf() < float(_data["alley_chance"]) else _pick_width(_data["streets"], rng.randf())
	var cut := rng.randi_range(smallest, length - smallest - width)
	var zone := Zone.ALLEY if width == 1 else Zone.ROAD
	# Strada senza uscita: parte da un lato e si ferma a metà; oltre ci sono
	# i cortili (il resto del taglio, vedi _district_code).
	var reach := across
	var from_start := true
	if across >= 2 * smallest and rng.randf() < float(_data["dead_end_chance"]):
		reach = rng.randi_range(across * 2 / 5, across * 3 / 4)
		from_start = rng.randf() < 0.5
	var offset := 0 if from_start else across - reach
	if along_x:
		district["streets"].append([Rect2i(rect.position.x + cut, rect.position.y + offset, width, reach), zone])
		_cut(Rect2i(rect.position, Vector2i(cut, rect.size.y)), rng, district, depth + 1)
		_cut(Rect2i(rect.position + Vector2i(cut + width, 0), Vector2i(rect.size.x - cut - width, rect.size.y)), rng, district, depth + 1)
	else:
		district["streets"].append([Rect2i(rect.position.x + offset, rect.position.y + cut, reach, width), zone])
		_cut(Rect2i(rect.position, Vector2i(rect.size.x, cut)), rng, district, depth + 1)
		_cut(Rect2i(rect.position + Vector2i(0, cut + width), Vector2i(rect.size.x, rect.size.y - cut - width)), rng, district, depth + 1)


## Isolato: piazza col giardino (a volte) o lotti dentro il marciapiede.
func _make_block(rect: Rect2i, rng: RandomNumberGenerator) -> Dictionary:
	var block := {"rect": rect, "square": false, "lots": [], "seed": rng.randi()}
	if mini(rect.size.x, rect.size.y) >= 6 and rng.randf() < float(_data["square_chance"]):
		block["square"] = true
		return block
	var inner := rect.size - Vector2i(2, 2)
	if inner.x > 0 and inner.y > 0:
		_split(Rect2i(Vector2i.ZERO, inner), rng, block["lots"])
	return block


func _block_code(block: Dictionary, local: Vector2i) -> int:
	var size: Vector2i = (block["rect"] as Rect2i).size
	if block["square"]:
		# Piazza lastricata con un giardino dalla forma irregolare in mezzo.
		var center := Vector2(size) / 2.0
		var offset := (Vector2(local) + Vector2(0.5, 0.5) - center) / (center * 0.85)
		var wobble := 0.18 * sin(offset.angle() * 3.0 + float(block["seed"] % 100)) + 0.1 * cos(offset.angle() * 5.0)
		return Zone.PARK if offset.length() < 0.8 + wobble else Zone.PLAZA
	if local.x == 0 or local.y == 0 or local.x == size.x - 1 or local.y == size.y - 1:
		return Zone.SIDEWALK
	var inner := local - Vector2i.ONE
	for lot: Dictionary in block["lots"]:
		var rect: Rect2i = lot["rect"]
		if rect.has_point(inner):
			return _lot_code(lot, inner - rect.position)
	# Tra un lotto e l'altro corre un vicoletto.
	return Zone.ALLEY


## Divide il rettangolo in lotti, a caso: lungo il lato più lungo, a volte
## con un vicoletto in mezzo.
func _split(rect: Rect2i, rng: RandomNumberGenerator, out: Array) -> void:
	var lot_min := int(_data["lot_min"])
	var lot_max := int(_data["lot_max"])
	var can_x := rect.size.x >= 2 * lot_min
	var can_y := rect.size.y >= 2 * lot_min
	var small := rect.size.x <= lot_max and rect.size.y <= lot_max
	if not (can_x or can_y) or (small and rng.randf() < 0.45):
		out.append(_make_lot(rect, rng))
		return
	var along_x := can_x and (not can_y or rect.size.x >= rect.size.y)
	var length := rect.size.x if along_x else rect.size.y
	var alley := 1 if rng.randf() < float(_data["lot_alley_chance"]) and length >= 2 * lot_min + 1 else 0
	var cut := rng.randi_range(lot_min, length - lot_min - alley)
	if along_x:
		_split(Rect2i(rect.position, Vector2i(cut, rect.size.y)), rng, out)
		_split(Rect2i(rect.position + Vector2i(cut + alley, 0), Vector2i(rect.size.x - cut - alley, rect.size.y)), rng, out)
	else:
		_split(Rect2i(rect.position, Vector2i(rect.size.x, cut)), rng, out)
		_split(Rect2i(rect.position + Vector2i(0, cut + alley), Vector2i(rect.size.x, rect.size.y - cut - alley)), rng, out)


## Sceglie cosa c'è nel lotto, pesato e secondo la grandezza, con altezza,
## stile, cortile, pianta a L e crollo.
func _make_lot(rect: Rect2i, rng: RandomNumberGenerator) -> Dictionary:
	var kinds: Dictionary = _data["lots"]
	var side := mini(rect.size.x, rect.size.y)
	var weights := {}
	var total := 0.0
	for kind: String in kinds:
		var info: Dictionary = kinds[kind]
		if side < int(info.get("min_size", 1)) or side > int(info.get("max_size", 99)):
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
	# Pianta a L: un angolo dell'edificio è un cortile.
	var built := side - 2 * int(lot["inset"])
	if info.has("height") and built >= 5 and rng.randf() < float(_data["notch_chance"]):
		var notch := Vector2i(rng.randi_range(2, built / 2), rng.randi_range(2, built / 2))
		var corner := Vector2i(rng.randi_range(0, 1), rng.randi_range(0, 1))
		var origin := Vector2i(int(lot["inset"]), int(lot["inset"]))
		var far := rect.size - origin - notch
		lot["notch"] = Rect2i(Vector2i(origin.x if corner.x == 0 else far.x, origin.y if corner.y == 0 else far.y), notch)
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
	if lot.has("notch") and (lot["notch"] as Rect2i).has_point(at):
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
## cortile e l'angolo della L) e non tra i pezzi di muro sul bordo crollati
## del tutto.
func _built(lot: Dictionary, at: Vector2i) -> bool:
	var rect: Rect2i = lot["rect"]
	var inset: int = lot["inset"]
	if at.x < inset or at.y < inset or at.x >= rect.size.x - inset or at.y >= rect.size.y - inset:
		return false
	if lot.has("notch") and (lot["notch"] as Rect2i).has_point(at):
		return false
	var edge := at.x == inset or at.y == inset or at.x == rect.size.x - inset - 1 or at.y == rect.size.y - inset - 1
	return not (edge and _unit([lot["seed"], at.x, at.y, "missing"]) < float(_data["missing_cell_chance"]))


## Numero a caso tra 0 e 1, sempre uguale per gli stessi valori (e il seme).
func _unit(values: Array) -> float:
	return float(absi(hash([seed_value] + values)) % 100000) / 100000.0
