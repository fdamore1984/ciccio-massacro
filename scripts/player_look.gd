class_name PlayerLook
## Aspetto di Ciccio, dal disegno di Valentina: una palla color pesca con
## gli occhioni cattivi e il ghigno pieno di denti, braccia e gambe lunghe
## fatte da una sola linea, guanti bianchi e la motosega rossa con la
## catena a denti grossi. Solo forme geometriche, come il resto del gioco.
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
## Occhi: raggio orizzontale rispetto alla palla (in verticale 1,3 volte).
const EYE_SIZE := 0.26
const EYE_STRETCH := 1.3
## Guardando quasi a nord (y sotto questa soglia) Ciccio è di spalle: niente faccia.
const FACE_HIDDEN_BELOW := -0.85
## Bocca: interno scuro quando è spalancata.
const COLOR_MOUTH := Color(0.23, 0.06, 0.05)
const MOUTH_TEETH := 8
## Guanti bianchi.
const COLOR_GLOVE := Color(1, 1, 1)
const GLOVE_RADIUS := 4.2
## Braccia: spalle sui fianchi della palla; la curva verso l'esterno è più
## ampia quando la mano è vicina (il braccio "avanza" di ARM_LENGTH).
const ARM_LENGTH := 30.0
const ARM_WIDTH := 3.0
const ARM_POINTS := 9
## Distanza delle mani dal centro: a riposo, negli attacchi, con la
## motosega alzata sopra la testa e piantata a terra dopo lo slam.
const HAND_REST := 1.6
const HAND_SWING := 1.45
const HAND_RAISED := 1.25
const HAND_PLANTED := 1.35
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
	Shapes.disc(canvas, Vector2.ZERO, RADIUS + Shapes.INK_WIDTH, Color(Shapes.INK, body.a))
	Shapes.disc(canvas, Vector2.ZERO, RADIUS, Color(body.darkened(SHADE), body.a))
	Shapes.disc(canvas, Vector2(-1.3, -1.6), RADIUS - 2.6, body)
	Shapes.oval(canvas, Vector2(-RADIUS * 0.42, -RADIUS * 0.5), Vector2(RADIUS * 0.22, RADIUS * 0.12),
			Color(COLOR_HIGHLIGHT, COLOR_HIGHLIGHT.a * body.a))


## Dove stanno occhi e bocca guardando verso facing: la faccia scivola
## verso il lato in cui si guarda e di profilo si stringe.
static func face(facing: Vector2) -> Dictionary:
	var size := RADIUS * EYE_SIZE
	var center := Vector2(facing.x * RADIUS * 0.45, facing.y * RADIUS * 0.22)
	return {
		"visible": facing.y > FACE_HIDDEN_BELOW,
		"look": facing,
		"size": size,
		"eyes": center + Vector2(0, -RADIUS * 0.3),
		"spacing": size * 1.2 * (1.0 - 0.35 * absf(facing.x)),
		"mouth": Vector2(center.x * 1.05, center.y + RADIUS * 0.42),
		"mouth_width": RADIUS * 0.5 * (1.0 - 0.35 * absf(facing.x)),
		"mouth_height": RADIUS * 0.3,
	}


## Bordo inferiore degli occhi, contorno compreso (vedi saw_in_front).
static func eye_bottom(look: Dictionary) -> float:
	return (look["eyes"] as Vector2).y + float(look["size"]) * EYE_STRETCH + 2.0


## Occhioni con la palpebra cattiva che scende verso il centro, la pupilla
## che guarda dove va Ciccio e il riflesso; blink li chiude.
static func draw_eyes(canvas: CanvasItem, look: Dictionary, body: Color, blink := false) -> void:
	var ink := Color(Shapes.INK, body.a)
	var white := Color(1, 1, 1, body.a)
	var direction: Vector2 = look["look"]
	for side: float in [-1.0, 1.0]:
		var eye: Vector2 = look["eyes"] + Vector2(side * float(look["spacing"]), 0)
		# L'occhio lontano, di profilo, è un po' più piccolo.
		var scale := 1.0 - 0.15 * maxf(0.0, -side * direction.x)
		var radii := Vector2(float(look["size"]), float(look["size"]) * EYE_STRETCH) * scale
		if blink:
			radii.y *= 0.18
		Shapes.oval(canvas, eye, radii + Vector2(2.0, 2.0), ink)
		Shapes.oval(canvas, eye, radii, white)
		if blink:
			continue
		var pupil := eye + direction * radii.x * 0.42 + Vector2(0, radii.y * 0.12)
		Shapes.disc(canvas, pupil, radii.x * 0.56, ink)
		Shapes.disc(canvas, pupil + Vector2(-radii.x * 0.2, -radii.x * 0.22), radii.x * 0.17, white)
		var outer := eye + Vector2(side * radii.x * 1.25, -radii.y * 1.02)
		var inner := eye + Vector2(-side * radii.x * 1.25, -radii.y * 0.28)
		var lid := _lid(eye, radii + Vector2(0.4, 0.4), outer, inner)
		if lid.size() >= 3:
			canvas.draw_colored_polygon(lid, body)
		canvas.draw_line(outer, inner, ink, maxf(2.2, radii.x * 0.42))


## Occhi a X (da morto).
static func draw_dead_eyes(canvas: CanvasItem, look: Dictionary, alpha := 1.0) -> void:
	var ink := Color(Shapes.INK, alpha)
	var size := float(look["size"])
	for side: float in [-1.0, 1.0]:
		var eye: Vector2 = look["eyes"] + Vector2(side * float(look["spacing"]), 0)
		canvas.draw_line(eye + Vector2(-size, -size), eye + Vector2(size, size), ink, 2.5)
		canvas.draw_line(eye + Vector2(-size, size), eye + Vector2(size, -size), ink, 2.5)


## Parte dell'ovale (centro, raggi) sopra la linea della palpebra
## (da outer a inner, che stanno fuori dall'ovale): la si colora come il
## corpo e l'occhio sembra socchiuso.
static func _lid(center: Vector2, radii: Vector2, outer: Vector2, inner: Vector2) -> PackedVector2Array:
	# Intersezioni tra la retta della palpebra e l'ovale (nello spazio in
	# cui l'ovale è un cerchio di raggio 1).
	var a := (outer - center) / radii
	var b := (inner - center) / radii
	var d := b - a
	var qa := d.dot(d)
	var qb := 2.0 * a.dot(d)
	var qc := a.dot(a) - 1.0
	var disc := qb * qb - 4.0 * qa * qc
	if disc <= 0.0 or qa == 0.0:
		return PackedVector2Array()
	var root := sqrt(disc)
	var p1 := a + d * ((-qb - root) / (2.0 * qa))
	var p2 := a + d * ((-qb + root) / (2.0 * qa))
	# Arco dell'ovale da p2 a p1 che passa dalla cima (angolo -PI/2).
	var from := p2.angle()
	var to := p1.angle()
	var sweep := wrapf(to - from, -PI, PI)
	var top_offset := wrapf(-PI / 2.0 - from, -PI, PI)
	if signf(top_offset) != signf(sweep) or absf(top_offset) > absf(sweep):
		sweep = sweep - TAU * signf(sweep)
	var points := PackedVector2Array()
	for k in 13:
		points.append(center + Vector2.from_angle(from + sweep * k / 12.0) * radii)
	return points


## Ghigno a mezzaluna con i denti: chiuso, una riga a zig-zag; spalancato
## (open fino a 1), due file di denti a punta sul fondo scuro.
static func draw_grin(canvas: CanvasItem, look: Dictionary, open := 0.0, alpha := 1.0) -> void:
	var ink := Color(Shapes.INK, alpha)
	var white := Color(1, 1, 1, alpha)
	var center: Vector2 = look["mouth"]
	var width := float(look["mouth_width"])
	var height := float(look["mouth_height"]) * (1.0 + 0.45 * open)
	var tilt := 1.0 if (look["look"] as Vector2).x >= 0.0 else -1.0
	# Un angolo della bocca più in alto dell'altro, dal lato in cui si guarda.
	var left := center + Vector2(-width, -height * 0.3 * (1.0 if tilt > 0.0 else 1.6))
	var right := center + Vector2(width, -height * 0.3 * (1.6 if tilt > 0.0 else 1.0))
	var top_control := center + Vector2(0, height * 0.05)
	var bottom_control := center + Vector2(0, height * 1.35)
	var outline := PackedVector2Array()
	for k in 11:
		outline.append(_inside(_bezier(left, top_control, right, k / 10.0)))
	for k in range(1, 10):
		outline.append(_inside(_bezier(right, bottom_control, left, k / 10.0)))
	var wide := open > 0.3
	canvas.draw_colored_polygon(outline, Color(COLOR_MOUTH, alpha) if wide else white)
	if wide:
		# Denti a punta: triangoli che scendono dal labbro di sopra e salgono da quello di sotto.
		var teeth_color := PackedColorArray([white])
		for i in range(0, MOUTH_TEETH - 1, 2):
			var t0 := 0.06 + 0.88 * i / MOUTH_TEETH
			var t1 := 0.06 + 0.88 * (i + 1) / MOUTH_TEETH
			var t2 := 0.06 + 0.88 * (i + 2) / MOUTH_TEETH
			for lip: Array in [[top_control, 0.38], [bottom_control, 0.32]]:
				var other := bottom_control if lip[0] == top_control else top_control
				var a := _inside(_bezier(left, lip[0], right, t0))
				var c := _inside(_bezier(left, lip[0], right, t2))
				var point := _inside(_bezier(left, lip[0], right, t1).lerp(_bezier(left, other, right, t1), float(lip[1])))
				var tooth := PackedVector2Array([a, point, c])
				canvas.draw_primitive(tooth, teeth_color, PackedVector2Array())
				tooth.append(a)
				canvas.draw_polyline(tooth, ink, 1.2)
	else:
		var zigzag := PackedVector2Array()
		for i in MOUTH_TEETH + 1:
			var t := 0.08 + 0.84 * i / MOUTH_TEETH
			var middle := _bezier(left, top_control, right, t).lerp(_bezier(left, bottom_control, right, t), 0.45)
			zigzag.append(_inside(middle + Vector2(0, (1.0 if i % 2 == 1 else -1.0) * height * 0.18)))
		canvas.draw_polyline(zigzag, ink, 1.5)
	var closed_outline := outline.duplicate()
	closed_outline.append(outline[0])
	canvas.draw_polyline(closed_outline, ink, 2.4)
	# Pieghe delle guance agli angoli.
	canvas.draw_line(_inside(left + Vector2(-1.5, -2.0)), _inside(left + Vector2(-0.5, 2.5)), ink, 1.4)
	canvas.draw_line(_inside(right + Vector2(1.5, -2.0)), _inside(right + Vector2(0.5, 2.5)), ink, 1.4)


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
		var shoulder := Vector2(float(pair[0]) * RADIUS * 0.86, RADIUS * 0.12)
		var middle := shoulder.lerp(hand, 0.5)
		var reach := (hand - shoulder).length()
		var out := middle.normalized() if middle.length() > 0.1 else hand.normalized()
		var bulge := sqrt(maxf(0.0, ARM_LENGTH * ARM_LENGTH - reach * reach)) * 0.4 + 3.0
		var control := middle + out * bulge
		var points := PackedVector2Array()
		for k in ARM_POINTS:
			points.append(_bezier(shoulder, control, hand, float(k) / (ARM_POINTS - 1)))
		canvas.draw_polyline(points, ink, ARM_WIDTH)


## Guanto bianco col polsino.
static func draw_glove(canvas: CanvasItem, at: Vector2, alpha := 1.0) -> void:
	Shapes.ink_disc(canvas, at, GLOVE_RADIUS, Color(COLOR_GLOVE, alpha), 2.0)
	canvas.draw_line(at + Vector2(-2.2, 2.6), at + Vector2(2.2, 2.6), Color(Shapes.INK, 0.35 * alpha), 1.0)


## Gambe: una linea ciascuna, appena piegata, con il piedino.
static func draw_legs(canvas: CanvasItem, hip_y: float, foot_y: float, spacing: float, phase: float,
		direction: Vector2, stride: float, facing: Vector2, tucked: bool, spread: float, alpha := 1.0) -> void:
	var ink := Color(Shapes.INK, alpha)
	for side: float in [-1.0, 1.0]:
		var swing := direction * sin(phase + (PI if side > 0.0 else 0.0)) * stride
		var hip := Vector2(side * spacing * 0.83, hip_y)
		var foot := Vector2(side * (spacing * 0.9 + 6.0 * spread) + swing.x, foot_y + swing.y * 0.5)
		if tucked:
			foot = Vector2(side * spacing, hip_y + 11.0)
		var knee := Vector2(lerpf(hip.x, foot.x, 0.5) + side * 2.5 + facing.x * 2.0, lerpf(hip.y, foot.y, 0.5))
		var points := PackedVector2Array()
		for k in 6:
			points.append(_bezier(hip, knee, foot, k / 5.0))
		canvas.draw_polyline(points, ink, ARM_WIDTH)
		var toe := Vector2(signf(facing.x) * 5.0, 0.0) if absf(facing.x) > 0.3 else Vector2(side * 3.0, 1.5)
		canvas.draw_line(foot, foot + toe, ink, 3.6)
