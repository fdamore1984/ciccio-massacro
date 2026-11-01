class_name PlayerLook
## Aspetto di Ciccio, dal disegno di Valentina: una palla color pesca
## sempre furiosa, con gli occhioni enormi fusi in un'unica forma, la bocca
## enorme nel quarto inferiore (denti serrati o spalancata), braccia e gambe
## fatte da una sola linea nera senza mani né piedi e la motosega rossa con
## la catena a denti grossi. Solo forme geometriche, come il resto del gioco.
##
## Regole perché la faccia resti sempre visibile (vedi Player._draw):
## - le braccia si disegnano prima della palla, che ne copre il tratto sul
##   corpo, quindi non passano mai sugli occhi;
## - la motosega va davanti alla palla solo se Ciccio non guarda a nord e
##   motosega e mani stanno sotto gli occhi (saw_in_front); alzata sopra la
##   testa passa dietro e la testa la copre; davanti può coprire la bocca;
## - gli occhi sono l'ultima cosa disegnata.
## Coordinate rispetto al centro della palla, in pixel di mondo.

const RADIUS := 22.0
## Ombreggiatura in basso a destra e riflesso in alto a sinistra.
const SHADE := 0.22
const COLOR_HIGHLIGHT := Color(1.0, 0.96, 0.91, 0.55)
## Contorno spesso della palla e delle forme della faccia.
const BALL_INK := 3.8
const FACE_INK := 3.2
## Occhioni enormi, sovrapposti e fusi in un'unica forma: raggio, distanza
## dal centro e altezza rispetto alla palla. La palpebra li taglia in
## diagonale, più bassa verso il centro (sempre furioso).
const EYE_SIZE := 0.6
const EYE_SPACING := 0.46
const EYE_HEIGHT := -0.24
const COLOR_IRIS := Color(0.27, 0.07, 0.05)
## Guardando quasi a nord (y sotto questa soglia) Ciccio è di spalle: niente faccia.
const FACE_HIDDEN_BELOW := -0.85
## Bocca: il quarto inferiore della palla; spalancata mostra l'interno.
const MOUTH_TOP := 0.3
const COLOR_MOUTH := Color(0.36, 0.06, 0.07)
const COLOR_THROAT := Color(0.06, 0.01, 0.01)
const COLOR_TONGUE := Color(0.86, 0.34, 0.39)
## Guanti bianchi.
const COLOR_GLOVE := Color(1, 1, 1)
const GLOVE_RADIUS := 4.2
## Braccia: spalle sui fianchi della palla; la curva verso l'esterno è più
## ampia quando la mano è vicina (il braccio "avanza" di ARM_LENGTH).
const ARM_LENGTH := 15.0
const ARM_WIDTH := 3.6
const ARM_POINTS := 9
## Distanza delle mani dal centro: a riposo, negli attacchi, con la
## motosega alzata sopra la testa e piantata a terra dopo lo slam.
const HAND_REST := 1.28
const HAND_SWING := 1.22
const HAND_RAISED := 1.12
const HAND_PLANTED := 1.17
## Motosega del disegno: motore rosso con il lato scuro, maniglia nera
## sopra, barra grigia col rivetto e denti a punta.
const COLOR_SAW_BODY := Color(0.8, 0.2, 0.16)
const COLOR_SAW_SIDE := Color(0.55, 0.12, 0.09)
const COLOR_SAW_BAR := Color(0.78, 0.8, 0.82)
const COLOR_SAW_BAR_LIGHT := Color(0.95, 0.95, 0.96)
const COLOR_SAW_TEETH := Color(0.23, 0.24, 0.26)
## Altezza della maniglia superiore rispetto alla metà larghezza del motore.
const SAW_HANDLE := 1.4


## Palla col contorno a inchiostro, l'ombra in basso a destra e il riflesso.
static func draw_ball(canvas: CanvasItem, body: Color) -> void:
	Shapes.disc(canvas, Vector2.ZERO, RADIUS + BALL_INK, Color(Shapes.INK, body.a))
	Shapes.disc(canvas, Vector2.ZERO, RADIUS, Color(body.darkened(SHADE), body.a))
	Shapes.disc(canvas, Vector2(-1.3, -1.6), RADIUS - 2.6, body)
	Shapes.oval(canvas, Vector2(-RADIUS * 0.42, -RADIUS * 0.5), Vector2(RADIUS * 0.22, RADIUS * 0.12),
			Color(COLOR_HIGHLIGHT, COLOR_HIGHLIGHT.a * body.a))


## Dove stanno occhi e bocca guardando verso facing: la faccia scivola
## verso il lato in cui si guarda e di profilo si stringe.
static func face(facing: Vector2) -> Dictionary:
	var center := Vector2(facing.x * RADIUS * 0.22, facing.y * RADIUS * 0.08)
	return {
		"visible": facing.y > FACE_HIDDEN_BELOW,
		"look": facing,
		"size": RADIUS * EYE_SIZE,
		"eyes": center + Vector2(0, RADIUS * EYE_HEIGHT),
		"spacing": RADIUS * EYE_SPACING * (1.0 - 0.3 * absf(facing.x)),
		"mouth": Vector2(center.x, RADIUS * MOUTH_TOP + center.y * 0.5),
		"mouth_width": RADIUS,
		"mouth_height": RADIUS * 0.1,
	}


## Bordo inferiore degli occhi, contorno compreso (vedi saw_in_front).
static func eye_bottom(look: Dictionary) -> float:
	return (look["eyes"] as Vector2).y + float(look["size"]) + FACE_INK


## Un occhio: cerchio tagliato in alto dalla palpebra, che scende verso il centro.
static func _eye_shape(eye: Vector2, radius: float, side: float, squash: float) -> PackedVector2Array:
	var outer := eye + Vector2(side * radius * 1.15, -radius * 0.88)
	var inner := eye + Vector2(-side * radius * 1.15, -radius * 0.02)
	var points := PackedVector2Array()
	for k in 40:
		var point := eye + Vector2.from_angle(TAU * k / 40.0) * radius
		var t := (point.x - outer.x) / (inner.x - outer.x)
		point.y = maxf(point.y, lerpf(outer.y, inner.y, t))
		point.y = eye.y + (point.y - eye.y) * squash
		points.append(point)
	return points


static func _circle(center: Vector2, radius: float, segments := 28) -> PackedVector2Array:
	var points := PackedVector2Array()
	for k in segments:
		points.append(center + Vector2.from_angle(TAU * k / segments) * radius)
	return points


## Riempie i poligoni risultanti da un'operazione di Geometry2D (salta i buchi).
static func _fill(canvas: CanvasItem, polygons: Array, color: Color) -> void:
	for polygon: PackedVector2Array in polygons:
		if polygon.size() >= 3 and not Geometry2D.is_polygon_clockwise(polygon):
			canvas.draw_colored_polygon(polygon, color)


## Occhioni fusi in un'unica forma bianca col contorno spesso, pupille
## piccole schiacciate contro la palpebra che guardano dove va Ciccio;
## blink li chiude.
static func draw_eyes(canvas: CanvasItem, look: Dictionary, body: Color, blink := false) -> void:
	draw_parts(canvas, eye_parts(look, blink), body.a, COLOR_IRIS)


## Parti degli occhi (vedi draw_parts): contorno, bianco, iride, pupilla e
## riflesso. Il colore "iris" si sceglie disegnando (i nemici lo cambiano).
static func eye_parts(look: Dictionary, blink := false) -> Array:
	var parts: Array = []
	var direction: Vector2 = look["look"]
	var shapes: Array[PackedVector2Array] = []
	var centers: Array[Vector2] = []
	var radii: Array[float] = []
	for side: float in [-1.0, 1.0]:
		var eye: Vector2 = look["eyes"] + Vector2(side * float(look["spacing"]), 0)
		# L'occhio lontano, di profilo, è un po' più piccolo.
		var radius := float(look["size"]) * (1.0 - 0.12 * maxf(0.0, -side * direction.x))
		shapes.append(_eye_shape(eye, radius, side, 0.18 if blink else 1.0))
		centers.append(eye)
		radii.append(radius)
	var merged := Geometry2D.merge_polygons(shapes[0], shapes[1])
	var outline: Array = []
	for polygon: PackedVector2Array in merged:
		if not Geometry2D.is_polygon_clockwise(polygon):
			outline.append_array(Geometry2D.offset_polygon(polygon, FACE_INK, Geometry2D.JOIN_ROUND))
	parts.append({"polygons": outline, "color": Shapes.INK})
	parts.append({"polygons": merged, "color": Color.WHITE})
	if blink:
		return parts
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var radius := radii[i]
		var pupil := centers[i] + Vector2(-side * radius * 0.2, radius * 0.13) + direction * radius * 0.2
		parts.append({"polygons": Geometry2D.intersect_polygons(_circle(pupil, radius * 0.32), shapes[i]), "color": "iris"})
		parts.append({"polygons": Geometry2D.intersect_polygons(_circle(pupil, radius * 0.22), shapes[i]), "color": Shapes.INK})
		parts.append({"disc": pupil + Vector2(-radius * 0.09, -radius * 0.1), "radius": radius * 0.075, "color": Color.WHITE})
	return parts


## Disegna le parti della faccia (vedi eye_parts e mouth_parts): poligoni
## (anche già pronti come mesh), linee e dischi.
static func draw_parts(canvas: CanvasItem, parts: Array, alpha: float, iris: Color) -> void:
	for part: Dictionary in parts:
		var color: Color = iris if typeof(part["color"]) == TYPE_STRING else part["color"]
		color.a *= alpha
		if part.has("meshes"):
			for mesh: ArrayMesh in part["meshes"]:
				canvas.draw_mesh(mesh, null, Transform2D.IDENTITY, color)
		elif part.has("polygons"):
			_fill(canvas, part["polygons"], color)
		elif part.has("line"):
			canvas.draw_polyline(part["line"], color, part["width"])
		elif part.has("disc"):
			Shapes.disc(canvas, part["disc"], part["radius"], color)


## Direzioni della faccia già pronta dei nemici (vedi enemy_face).
const FACE_DIRECTIONS := 16
## Grandezze degli occhi dei nemici, rispetto a quelli di Ciccio.
const ENEMY_EYE_SCALES := [0.8, 0.9, 1.0, 1.1]
## Faccia dei nemici già pronta in mesh, per chiave (vedi enemy_face).
static var _enemy_faces := {}


## Faccia di Ciccio per i nemici, che gli somigliano: le operazioni sui
## poligoni costano troppo per centinaia di nemici a ogni frame, quindi le
## parti si preparano una volta sola per direzione (FACE_DIRECTIONS),
## grandezza degli occhi e bocca, come mesh. Coordinate di Ciccio (raggio
## RADIUS): chi chiama scala il disegno sul proprio raggio.
## mouth: "teeth" (denti serrati) o "scream" (spalancata).
static func enemy_face(canvas: CanvasItem, facing: Vector2, eye_scale: float, mouth: String, iris: Color) -> void:
	var direction := wrapi(roundi(facing.angle() / TAU * FACE_DIRECTIONS), 0, FACE_DIRECTIONS)
	var key := "%d:%s:%s" % [direction, eye_scale, mouth]
	if not _enemy_faces.has(key):
		_enemy_faces[key] = _build_enemy_face(Vector2.from_angle(TAU * direction / FACE_DIRECTIONS), eye_scale, mouth, key)
	draw_parts(canvas, _enemy_faces[key], 1.0, iris)


## Prepara in anticipo tutte le facce dei nemici (durante un caricamento),
## così la prima volta che si vedono non costano nulla. Ne prepara al più
## count e dice se ne mancano ancora.
static func prepare_enemy_faces(count: int) -> bool:
	for direction in FACE_DIRECTIONS:
		for eye_scale: float in ENEMY_EYE_SCALES:
			for mouth: String in ["teeth", "scream"]:
				var key := "%d:%s:%s" % [direction, eye_scale, mouth]
				if _enemy_faces.has(key):
					continue
				if count <= 0:
					return true
				count -= 1
				_enemy_faces[key] = _build_enemy_face(Vector2.from_angle(TAU * direction / FACE_DIRECTIONS), eye_scale, mouth, key)
	return false


static func _build_enemy_face(facing: Vector2, eye_scale: float, mouth: String, key: String) -> Array:
	var look := face(facing)
	if not look["visible"]:
		return []
	look["size"] = float(look["size"]) * eye_scale
	look["spacing"] = float(look["spacing"]) * lerpf(1.0, eye_scale, 0.5)
	var parts := mouth_parts(look, 1.0 if mouth == "scream" else 0.0)
	parts.append_array(eye_parts(look))
	var baked: Array = []
	for k in parts.size():
		var part: Dictionary = parts[k]
		if part.has("polygons"):
			var meshes: Array[ArrayMesh] = []
			for n in (part["polygons"] as Array).size():
				var polygon: PackedVector2Array = part["polygons"][n]
				if polygon.size() >= 3 and not Geometry2D.is_polygon_clockwise(polygon):
					meshes.append(Shapes.polygon_mesh(["enemy_face", key, k, n], polygon))
			baked.append({"meshes": meshes, "color": part["color"]})
		else:
			baked.append(part)
	return baked


## Occhi a X (da morto).
static func draw_dead_eyes(canvas: CanvasItem, look: Dictionary, alpha := 1.0) -> void:
	var ink := Color(Shapes.INK, alpha)
	var size := float(look["size"]) * 0.45
	for side: float in [-1.0, 1.0]:
		var eye: Vector2 = look["eyes"] + Vector2(side * float(look["spacing"]), 0)
		canvas.draw_line(eye + Vector2(-size, -size), eye + Vector2(size, size), ink, FACE_INK)
		canvas.draw_line(eye + Vector2(-size, size), eye + Vector2(size, -size), ink, FACE_INK)


## Bocca enorme: il quarto inferiore della palla, tagliato dal bordo. Il
## labbro di sopra è quasi dritto con gli angoli in giù. Chiusa è tutta
## denti serrati (una riga con due zig-zag morbidi); spalancata (open oltre
## 0,3) mostra gola, ugola e lingua, senza denti.
static func draw_grin(canvas: CanvasItem, look: Dictionary, open := 0.0, alpha := 1.0) -> void:
	draw_parts(canvas, mouth_parts(look, open), alpha, COLOR_IRIS)


## Parti della bocca (vedi draw_parts e draw_grin).
static func mouth_parts(look: Dictionary, open := 0.0) -> Array:
	var parts: Array = []
	var center: Vector2 = look["mouth"]
	var lip := PackedVector2Array()
	for k in 21:
		var t := k / 10.0 - 1.0
		lip.append(center + Vector2(t * (RADIUS + 3.0), RADIUS * (0.08 * absf(t) - 0.03 * (1.0 - t * t))))
	var shape := lip.duplicate()
	shape.append(Vector2(center.x + RADIUS + 6.0, RADIUS + 6.0))
	shape.append(Vector2(center.x - RADIUS - 6.0, RADIUS + 6.0))
	var mouth := Geometry2D.intersect_polygons(shape, _circle(Vector2.ZERO, RADIUS, 40))
	if mouth.is_empty():
		return parts
	var area: PackedVector2Array = mouth[0]
	if open > 0.3:
		parts.append({"polygons": [area], "color": COLOR_MOUTH})
		var throat := PackedVector2Array()
		for k in 20:
			throat.append(center + Vector2(0, RADIUS * 0.3) + Vector2.from_angle(TAU * k / 20.0) * Vector2(RADIUS * 0.45, RADIUS * 0.2))
		parts.append({"polygons": Geometry2D.intersect_polygons(throat, area), "color": COLOR_THROAT})
		parts.append({"polygons": Geometry2D.intersect_polygons(_circle(Vector2(center.x - RADIUS * 0.05, RADIUS * 1.2), RADIUS * 0.56), area),
				"color": COLOR_TONGUE})
		parts.append({"polygons": [PackedVector2Array([center + Vector2(-1.0, 0), center + Vector2(1.0, 0),
				center + Vector2(0, RADIUS * 0.14)])], "color": COLOR_TONGUE.darkened(0.25)})
	else:
		parts.append({"polygons": [area], "color": Color.WHITE})
		var line := PackedVector2Array()
		for k in 29:
			var x := (k / 14.0 - 1.0) * RADIUS * 0.68
			var y := RADIUS * 0.43 - x * x / (RADIUS * 8.8)
			for zig: Array in [[-0.48, -0.27, 0.05, 1.0], [0.13, 0.3, 0.045, -1.0]]:
				var u := (x / RADIUS - float(zig[0])) / (float(zig[1]) - float(zig[0]))
				if u > 0.0 and u < 1.0:
					y += RADIUS * float(zig[2]) * sin(u * TAU) * float(zig[3])
			line.append(_inside(center + Vector2(x, y)))
		parts.append({"line": line, "width": FACE_INK * 0.6, "color": Shapes.INK})
	var edge := PackedVector2Array()
	for point in lip:
		edge.append(point.limit_length(RADIUS))
	parts.append({"line": edge, "width": FACE_INK, "color": Shapes.INK})
	return parts


## Bocca chiusa da morto: una linea storta.
static func draw_dead_mouth(canvas: CanvasItem, look: Dictionary, alpha := 1.0) -> void:
	var center: Vector2 = look["mouth"]
	var width := float(look["mouth_width"]) * 0.6
	canvas.draw_polyline(PackedVector2Array([center + Vector2(-width, 1.0), center + Vector2(-width * 0.3, -1.0),
			center + Vector2(width * 0.3, 1.0), center + Vector2(width, -1.0)]), Color(Shapes.INK, alpha), 2.0)


static func _bezier(a: Vector2, control: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(control, t).lerp(control.lerp(b, t), t)


## Tiene un punto della faccia dentro la palla (di profilo la bocca arriva al bordo).
static func _inside(point: Vector2) -> Vector2:
	return point.limit_length(RADIUS - 1.5)


## Posa a riposo: la mano sul fianco verso la telecamera (a destra se si
## guarda a sud o a nord), la motosega puntata in avanti e in fuori.
## Restituisce [mano, angolo].
static func rest_hold(facing: Vector2) -> Array:
	var perp := Vector2(-facing.y, facing.x)
	var turn := 1.0
	if not (perp.y > 0.05 or (absf(perp.y) <= 0.05 and perp.x > 0.0)):
		perp = -perp
		turn = -1.0
	var direction := (facing * 0.55 + perp * 0.85).normalized()
	return [direction * RADIUS * HAND_REST, facing.angle() + 0.5 * turn]


## Lato della motosega con la maniglia superiore (verso l'alto dello schermo).
static func _saw_top(angle: float) -> Vector2:
	var side := Vector2.from_angle(angle).orthogonal()
	return side if side.y <= 0.0 else -side


## Posizione delle due mani sulla maniglia superiore: [dietro, avanti].
static func saw_hands(origin: Vector2, angle: float, length: float, width: float) -> Array:
	var direction := Vector2.from_angle(angle)
	var top := _saw_top(angle) * width * 1.45 * SAW_HANDLE
	return [origin + direction * width * 0.1 + top, origin + direction * length * 0.24 + top]


## La motosega (impugnata in origin) va davanti alla palla? Solo se non si
## guarda a nord e motosega e mani stanno sotto gli occhi.
static func saw_in_front(facing: Vector2, origin: Vector2, hands: Array, look: Dictionary) -> bool:
	if BodyParts.gear_behind(facing) or origin.y < RADIUS * 0.5:
		return false
	if not look["visible"]:
		return true
	var lowest := minf((hands[0] as Vector2).y, (hands[1] as Vector2).y)
	return lowest - GLOVE_RADIUS - 2.3 > eye_bottom(look)


## Motosega del disegno impugnata in origin e puntata nell'angolo dato:
## denti a punta che scorrono (phase in pixel), barra col rivetto, motore
## rosso con la maniglia nera; heat (0-1) la fa brillare d'arancione.
static func draw_chainsaw(canvas: CanvasItem, origin: Vector2, angle: float, length: float, width: float,
		tint := Color.WHITE, phase := 0.0, heat := 0.0) -> void:
	var ink := Color(Shapes.INK, tint.a)
	var direction := Vector2.from_angle(angle)
	var top := _saw_top(angle)
	var engine := width * 1.45
	var bar := width * 0.72
	var body_end := origin + direction * length * 0.34
	var tip := origin + direction * (length - bar)
	# Denti della catena: triangoli sui due bordi, inclinati verso il verso di scorrimento.
	var spacing := width * 1.7
	var run := (tip - body_end).length()
	var at := fposmod(phase, spacing)
	var teeth_color := COLOR_SAW_TEETH * tint
	while at < run + bar:
		for edge: float in [1.0, -1.0]:
			var base := body_end + direction * (at if edge > 0.0 else run - at) + top * edge * bar
			var tooth := PackedVector2Array([base - direction * width * 0.36, base + direction * width * 0.36,
					base + top * edge * width * 0.8 + direction * edge * width * 0.35])
			canvas.draw_primitive(tooth, PackedColorArray([teeth_color]), PackedVector2Array())
			tooth.append(tooth[0])
			canvas.draw_polyline(tooth, ink, 1.1)
		at += spacing
	# Barra con la punta tonda, il riflesso e il rivetto.
	canvas.draw_line(body_end, tip, ink, bar * 2.0 + 2.6)
	Shapes.disc(canvas, tip, bar + 1.3, ink)
	canvas.draw_primitive(PackedVector2Array([body_end + top * bar, tip + top * bar, tip - top * bar, body_end - top * bar]),
			PackedColorArray([COLOR_SAW_BAR * tint]), PackedVector2Array())
	Shapes.disc(canvas, tip, bar, COLOR_SAW_BAR * tint)
	canvas.draw_line(body_end + top * bar * 0.45, tip + top * bar * 0.45, COLOR_SAW_BAR_LIGHT * tint, width * 0.22)
	Shapes.disc(canvas, tip - direction * bar * 0.5, width * 0.3, ink)
	if heat > 0.0:
		Shapes.glow(canvas, body_end.lerp(tip, 0.6), length * 0.5, Color(1.0, 0.67, 0.24, 0.5 * heat))
	# Impugnatura posteriore ad anello.
	var back := origin - direction * width * 0.5
	canvas.draw_polyline(PackedVector2Array([back + top * engine * 0.4, back - direction * width + top * engine * 0.4,
			back - direction * width - top * engine * 0.6, back - top * engine * 0.6]), ink, width * 0.55)
	# Motore rosso col lato scuro e un riflesso.
	var rear := origin - direction * width * 0.6
	var shell := PackedVector2Array([rear + top * engine * 0.95, body_end + top * engine * 0.85,
			body_end - top * engine * 0.85, rear - top * engine * 0.95])
	canvas.draw_primitive(shell, PackedColorArray([COLOR_SAW_BODY * tint]), PackedVector2Array())
	canvas.draw_primitive(PackedVector2Array([rear - top * engine * 0.15, body_end - top * engine * 0.15, shell[2], shell[3]]),
			PackedColorArray([COLOR_SAW_SIDE * tint]), PackedVector2Array())
	canvas.draw_line(rear + direction * width * 0.6 + top * engine * 0.55, body_end - direction * width * 0.6 + top * engine * 0.5,
			Color(1, 1, 1, 0.35 * tint.a), width * 0.3)
	var closed := shell.duplicate()
	closed.append(shell[0])
	canvas.draw_polyline(closed, ink, 2.8)
	# Maniglia nera sopra il motore.
	var front := origin + direction * length * 0.24
	var start := origin + direction * width * 0.1
	canvas.draw_polyline(PackedVector2Array([start + top * engine * 0.9, start + top * engine * SAW_HANDLE,
			front + top * engine * SAW_HANDLE, front + top * engine * 0.9]), ink, width * 0.75)


## Braccia: una linea per lato, dalla spalla sul fianco della palla alla
## mano, curva verso l'esterno. Vanno disegnate prima della palla.
static func draw_arms(canvas: CanvasItem, first: Vector2, second: Vector2, alpha := 1.0) -> void:
	var ink := Color(Shapes.INK, alpha)
	var pairs := [[1.0, first], [-1.0, second]] if first.x >= second.x else [[-1.0, first], [1.0, second]]
	for pair: Array in pairs:
		var hand: Vector2 = pair[1]
		var shoulder := Vector2(float(pair[0]) * RADIUS * 0.9, -RADIUS * 0.3)
		var middle := shoulder.lerp(hand, 0.5)
		var reach := (hand - shoulder).length()
		var out := middle.normalized() if middle.length() > 0.1 else hand.normalized()
		var bulge := sqrt(maxf(0.0, ARM_LENGTH * ARM_LENGTH - reach * reach)) * 0.4 + 3.0
		var control := middle + out * bulge
		var points := PackedVector2Array()
		for k in ARM_POINTS:
			points.append(_bezier(shoulder, control, hand, float(k) / (ARM_POINTS - 1)))
		canvas.draw_polyline(points, ink, ARM_WIDTH)


## Niente mani: il braccio finisce con la punta tonda della linea.
static func draw_glove(canvas: CanvasItem, at: Vector2, alpha := 1.0) -> void:
	Shapes.disc(canvas, at, ARM_WIDTH * 0.5, Color(Shapes.INK, alpha))


## Gambe: una linea ciascuna, appena piegata, con il piedino.
static func draw_legs(canvas: CanvasItem, hip_y: float, foot_y: float, spacing: float, phase: float,
		direction: Vector2, stride: float, facing: Vector2, tucked: bool, spread: float, alpha := 1.0) -> void:
	var ink := Color(Shapes.INK, alpha)
	for side: float in [-1.0, 1.0]:
		var swing := direction * sin(phase + (PI if side > 0.0 else 0.0)) * stride
		var hip := Vector2(side * spacing * 1.05, hip_y)
		var foot := Vector2(side * (spacing * 1.15 + 6.0 * spread) + swing.x, foot_y + swing.y * 0.5)
		if tucked:
			foot = Vector2(side * spacing, hip_y + 6.0)
		var knee := Vector2(lerpf(hip.x, foot.x, 0.5) + side * 2.5 + facing.x * 2.0, lerpf(hip.y, foot.y, 0.5))
		var points := PackedVector2Array()
		for k in 6:
			points.append(_bezier(hip, knee, foot, k / 5.0))
		canvas.draw_polyline(points, ink, ARM_WIDTH)
		Shapes.disc(canvas, foot, ARM_WIDTH * 0.5, ink)
