class_name BodyParts
## Parti del corpo e armi disegnate con forme geometriche, comuni a
## giocatore e nemici: gambe che camminano, la motosega del giocatore, le
## armi contundenti (mazze, manganelli, tubi, mazze da demolizione) e le
## armi da fuoco dei nemici. Provvisorie, in attesa degli sprite definitivi.

## Motosega: motore, impugnatura, barra e catena.
const COLOR_SAW_BODY := Color(0.92, 0.42, 0.12)
const COLOR_SAW_COVER := Color(0.2, 0.2, 0.22)
const COLOR_SAW_BAR := Color(0.78, 0.8, 0.84)
const COLOR_SAW_CHAIN := Color(0.25, 0.25, 0.27)
const COLOR_SAW_GRIP := Color(0.12, 0.12, 0.13)
## Armi contundenti dei nemici (vedi draw_club) e armi da fuoco (draw_gun).
const COLOR_WOOD := Color(0.62, 0.45, 0.26)
const COLOR_STEEL := Color(0.62, 0.64, 0.68)
const COLOR_RUBBER := Color(0.13, 0.13, 0.14)
const COLOR_GUN := Color(0.18, 0.18, 0.2)
const COLOR_GUN_WOOD := Color(0.45, 0.3, 0.17)
## Prospettiva isometrica: chi guarda verso nord (verso l'alto dello
## schermo, sguardo con y sotto questa soglia) ha davanti a sé la parte del
## corpo lontana dalla telecamera, e gli elementi montati sul corpo (armi,
## braccia, torcia, scorte, faccia) vanno disegnati prima del corpo, che li
## copre; guardando a sud restano davanti al corpo.
const BEHIND_FACING := -0.2


## True se gli elementi montati sul corpo vanno dietro al corpo (vedi BEHIND_FACING).
static func gear_behind(facing: Vector2) -> bool:
	return facing.y < BEHIND_FACING


## Due gambe dai fianchi ai piedi. phase avanza camminando: i piedi si
## spostano avanti e indietro lungo la direzione di movimento (direction);
## stride 0 = fermi o in aria. feet = false: semplici linee, senza piedi.
static func draw_legs(canvas: CanvasItem, hip_y: float, foot_y: float, spacing: float, width: float,
		phase: float, direction: Vector2, stride: float, color: Color, feet := true) -> void:
	for side: float in [-1.0, 1.0]:
		var swing := direction * sin(phase + (PI if side > 0.0 else 0.0)) * stride
		var hip := Vector2(side * spacing, hip_y)
		var foot := Vector2(side * spacing, foot_y) + Vector2(swing.x, swing.y * 0.5)
		canvas.draw_line(hip, foot, color, width)
		if feet:
			Shapes.disc(canvas, foot, width * 0.6, color.darkened(0.25))


## Motosega impugnata in origin (impugnatura posteriore) e puntata
## nell'angolo dato: motore arancione, barra che si allunga fino alla punta
## arrotondata e dentini della catena che scorrono lungo i bordi (phase
## avanza in pixel: più veloce quando la catena gira forte).
static func draw_chainsaw(canvas: CanvasItem, origin: Vector2, angle: float, length: float, width: float,
		tint := Color.WHITE, phase := 0.0) -> void:
	var direction := Vector2.from_angle(angle)
	var side := direction.orthogonal()
	var engine := width * 1.45
	var body_end := origin + direction * length * 0.36
	var bar := width * 0.72
	var tip := origin + direction * (length - bar)
	# Impugnatura posteriore ad anello.
	canvas.draw_polyline(PackedVector2Array([origin + side * engine * 0.7, origin - direction * width * 0.9 + side * engine * 0.7,
			origin - direction * width * 0.9 - side * engine * 0.5, origin - side * engine * 0.5]), COLOR_SAW_GRIP, maxf(width * 0.45, 1.5))
	# Barra con la punta tonda.
	var steel := PackedColorArray([COLOR_SAW_BAR * tint])
	canvas.draw_primitive(PackedVector2Array([body_end + side * bar, tip + side * bar, tip - side * bar, body_end - side * bar]), steel, PackedVector2Array())
	Shapes.disc(canvas, tip, bar, COLOR_SAW_BAR * tint)
	# Catena: dentini su entrambi i bordi della barra, che scorrono.
	var spacing := maxf(width * 1.1, 3.0)
	var teeth := PackedVector2Array()
	var run := (tip - body_end).length()
	var shift := fposmod(phase, spacing)
	var at := shift
	while at < run:
		for edge: float in [1.0, -1.0]:
			var base := body_end + direction * (at if edge > 0.0 else run - at) + side * edge * bar
			teeth.append(base)
			teeth.append(base + side * edge * width * 0.4 + direction * edge * width * 0.25)
		at += spacing
	if not teeth.is_empty():
		canvas.draw_multiline(teeth, COLOR_SAW_CHAIN, maxf(width * 0.3, 1.0))
	# Motore con il coperchio scuro e la maniglia anteriore.
	canvas.draw_primitive(PackedVector2Array([origin + side * engine, body_end + side * engine * 0.8,
			body_end - side * engine * 0.8, origin - side * engine]), PackedColorArray([COLOR_SAW_BODY * tint]), PackedVector2Array())
	canvas.draw_primitive(PackedVector2Array([origin + direction * length * 0.06 + side * engine * 0.45, body_end - direction * width * 0.4 + side * engine * 0.4,
			body_end - direction * width * 0.4 - side * engine * 0.4, origin + direction * length * 0.06 - side * engine * 0.45]),
			PackedColorArray([COLOR_SAW_COVER]), PackedVector2Array())
	canvas.draw_line(origin + direction * length * 0.2 - side * engine * 1.25, origin + direction * length * 0.2 + side * engine * 1.25,
			COLOR_SAW_GRIP, maxf(width * 0.4, 1.5))


## Arma contundente impugnata in origin e puntata nell'angolo dato:
## "bat" mazza da baseball di legno che si allarga verso la cima, "nailbat"
## la stessa con i chiodi, "baton" manganello nero con l'impugnatura
## laterale, "pipe" tubo di ferro, "sledge" mazza da demolizione col
## manico lungo e la testa pesante.
static func draw_club(canvas: CanvasItem, origin: Vector2, angle: float, length: float, width: float,
		kind := "bat", tint := Color.WHITE) -> void:
	var direction := Vector2.from_angle(angle)
	var side := direction.orthogonal()
	var tip := origin + direction * length
	match kind:
		"baton":
			canvas.draw_line(origin, tip, COLOR_RUBBER * tint, width * 0.8)
			var handle := origin + direction * length * 0.22
			canvas.draw_line(handle, handle + side * width * 1.6, COLOR_RUBBER * tint, width * 0.6)
			canvas.draw_line(origin + direction * length * 0.3, tip, Color(1, 1, 1, 0.18) * tint, maxf(width * 0.2, 1.0))
		"pipe":
			canvas.draw_line(origin, tip, COLOR_STEEL.darkened(0.15) * tint, width * 0.75)
			canvas.draw_line(origin + side * width * 0.15, tip + side * width * 0.15, COLOR_STEEL.lightened(0.25) * tint, maxf(width * 0.2, 1.0))
			canvas.draw_line(tip - side * width * 0.6, tip + side * width * 0.6, COLOR_STEEL.darkened(0.3) * tint, width * 0.7)
			canvas.draw_line(origin, origin + direction * length * 0.2, COLOR_RUBBER, width * 0.85)
		"sledge":
			canvas.draw_line(origin, tip, COLOR_WOOD * tint, width * 0.55)
			var head := PackedVector2Array([tip - direction * width * 1.1 + side * width * 1.6, tip + side * width * 1.6,
					tip - side * width * 1.6, tip - direction * width * 1.1 - side * width * 1.6])
			canvas.draw_primitive(head, PackedColorArray([COLOR_STEEL.darkened(0.25) * tint]), PackedVector2Array())
			canvas.draw_line(tip + side * width * 1.6, tip - side * width * 1.6, COLOR_STEEL.lightened(0.2) * tint, maxf(width * 0.3, 1.0))
		_:
			# Mazza: stretta all'impugnatura, larga e arrotondata in cima.
			var grip := origin + direction * length * 0.25
			canvas.draw_line(origin, grip, COLOR_RUBBER, width * 0.5)
			canvas.draw_primitive(PackedVector2Array([grip + side * width * 0.28, tip + side * width * 0.62,
					tip - side * width * 0.62, grip - side * width * 0.28]), PackedColorArray([COLOR_WOOD * tint]), PackedVector2Array())
			Shapes.disc(canvas, tip, width * 0.62, COLOR_WOOD * tint)
			if kind == "nailbat":
				var nails := PackedVector2Array()
				for k in 4:
					var at := origin + direction * length * (0.6 + 0.12 * k)
					var out := side * width * (0.95 if k % 2 == 0 else -0.95)
					nails.append(at)
					nails.append(at + out)
				canvas.draw_multiline(nails, COLOR_STEEL.lightened(0.3), maxf(width * 0.18, 1.0))


## Arma da fuoco impugnata in origin e puntata nell'angolo dato: "pistol"
## corta, "rifle" lunga col calcio di legno, "shotgun" a due canne.
## flash (0-1) accende la vampata alla bocca della canna.
static func draw_gun(canvas: CanvasItem, origin: Vector2, angle: float, length: float, width: float,
		kind := "pistol", flash := 0.0) -> void:
	var direction := Vector2.from_angle(angle)
	var side := direction.orthogonal()
	var muzzle := origin + direction * length
	match kind:
		"rifle", "shotgun":
			var stock := origin - direction * length * 0.3
			canvas.draw_line(stock + side * width * 0.4, origin, COLOR_GUN_WOOD, width * 1.2)
			canvas.draw_line(origin, origin + direction * length * 0.4, COLOR_GUN, width * 1.1)
			if kind == "shotgun":
				canvas.draw_line(origin + side * width * 0.3, muzzle + side * width * 0.3, COLOR_GUN, width * 0.55)
				canvas.draw_line(origin - side * width * 0.3, muzzle - side * width * 0.3, COLOR_GUN, width * 0.55)
				canvas.draw_line(origin + direction * length * 0.45 + side * width * 0.8, origin + direction * length * 0.7 + side * width * 0.8, COLOR_GUN_WOOD, width * 0.7)
			else:
				canvas.draw_line(origin, muzzle, COLOR_GUN, width * 0.5)
				canvas.draw_line(origin + direction * length * 0.25 - side * width * 0.9, origin + direction * length * 0.5 - side * width * 0.9, COLOR_GUN.lightened(0.2), width * 0.6)
		_:
			canvas.draw_line(origin, muzzle, COLOR_GUN, width)
			canvas.draw_line(origin, origin + side * width * 1.2 - direction * width * 0.3, COLOR_GUN.lightened(0.1), width * 0.9)
	if flash > 0.0:
		Shapes.disc(canvas, muzzle + direction * width * 1.5, width * 2.6 * flash, Color(1.0, 0.75, 0.3, 0.85 * flash))
		Shapes.disc(canvas, muzzle + direction * width * 1.2, width * 1.3 * flash, Color(1.0, 1.0, 0.8, flash))


## Scia del fendente: una fascia ad arco tra from_angle e to_angle, più
## accesa verso il bordo che si sta muovendo.
static func draw_trail(canvas: CanvasItem, center: Vector2, from_angle: float, to_angle: float,
		inner: float, outer: float, color: Color) -> void:
	var steps := 14
	for i in steps:
		var a := lerpf(from_angle, to_angle, float(i) / steps)
		var b := lerpf(from_angle, to_angle, float(i + 1) / steps)
		var piece := PackedVector2Array([
			center + Vector2.from_angle(a) * inner, center + Vector2.from_angle(a) * outer,
			center + Vector2.from_angle(b) * outer, center + Vector2.from_angle(b) * inner,
		])
		canvas.draw_primitive(piece, PackedColorArray([Color(color, color.a * float(i + 1) / steps)]), PackedVector2Array())
