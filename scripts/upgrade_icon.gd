class_name UpgradeIcon
extends Control
## Icona geometrica di un potenziamento o di un effetto attivo, disegnata in
## codice in attesa delle icone definitive. Si adatta alla dimensione del
## controllo.

## Colore di ogni icona: aiuta a distinguerle a colpo d'occhio.
const COLORS := {
	"combo": Color(1.0, 0.95, 0.75),
	"heavy": Color(1.0, 0.55, 0.2),
	"dodge": Color(0.45, 0.85, 1.0),
	"jump": Color(0.5, 0.95, 0.55),
	"health": Color(0.95, 0.35, 0.35),
	"potion": Color(0.95, 0.3, 0.3),
	"battery_potion": Color(0.3, 0.85, 0.3),
	"shield": Color(0.6, 0.7, 0.8),
	"run": Color(1.0, 0.85, 0.3),
	"empowered": Color(1.0, 0.8, 0.25),
	"bubble": Color(0.72, 0.8, 0.88),
	"mana": Color(0.95, 0.4, 0.15),
	"spell": Color(0.55, 0.6, 0.38),
	"torch": Color(0.92, 0.95, 1.0),
	"bag": Color(0.8, 0.6, 0.35),
	"battery": Color(0.4, 0.85, 0.35),
	"potion_slots": Color(0.95, 0.6, 0.75),
	"potion_heal": Color(0.95, 0.35, 0.35),
	"mana_restore": Color(0.95, 0.4, 0.15),
	"choice": Color(0.95, 0.85, 0.45),
}

@export var kind := "":
	set(value):
		kind = value
		queue_redraw()


static func color_of(icon_kind: String) -> Color:
	return COLORS.get(icon_kind, Color.WHITE)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_icon(self, size / 2.0, minf(size.x, size.y), kind)


## Disegna l'icona centrata in center, larga side pixel; frame = false
## per non disegnare il cerchio di sfondo.
static func draw_icon(canvas: CanvasItem, center: Vector2, side: float, icon_kind: String, frame := true) -> void:
	# Le forme sono pensate in un quadrato da -1 a 1.
	canvas.draw_set_transform(center, 0.0, Vector2.ONE * side / 2.0)
	var color := color_of(icon_kind)
	if frame:
		canvas.draw_circle(Vector2.ZERO, 0.98, Color(0, 0, 0, 0.35))
		canvas.draw_arc(Vector2.ZERO, 0.98, 0.0, TAU, 32, Color(color, 0.6), 0.06)
	match icon_kind:
		"combo":
			# Tre fendenti obliqui, sempre più lunghi.
			for k in 3:
				var x := -0.4 + k * 0.35
				var length := 0.3 + k * 0.12
				canvas.draw_line(Vector2(x - length * 0.5, length), Vector2(x + length * 0.5, -length), color, 0.12)
		"heavy":
			# Stella a otto punte: il colpo potente.
			var points := PackedVector2Array()
			for k in 16:
				points.append(Vector2.from_angle(TAU * k / 16.0 - PI / 2.0) * (0.7 if k % 2 == 0 else 0.3))
			canvas.draw_colored_polygon(points, color)
		"dodge":
			# Due frecce verso destra, come una scia.
			for k in 2:
				var x := -0.45 + k * 0.45
				canvas.draw_polyline(PackedVector2Array([Vector2(x, -0.4), Vector2(x + 0.35, 0.0), Vector2(x, 0.4)]), Color(color, 0.55 + 0.45 * k), 0.14)
		"jump":
			# Freccia verso l'alto sopra il terreno.
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, -0.65), Vector2(0.4, -0.15), Vector2(-0.4, -0.15)]), color)
			canvas.draw_rect(Rect2(-0.14, -0.2, 0.28, 0.5), color)
			canvas.draw_line(Vector2(-0.55, 0.5), Vector2(0.55, 0.5), color, 0.1)
		"health":
			# Cuore: due cerchi e un triangolo.
			canvas.draw_circle(Vector2(-0.24, -0.15), 0.28, color)
			canvas.draw_circle(Vector2(0.24, -0.15), 0.28, color)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-0.5, -0.05), Vector2(0.5, -0.05), Vector2(0, 0.6)]), color)
		"potion":
			# Kit medico: valigetta bianca con la croce rossa.
			_draw_medkit(canvas, Vector2(0, 0.05), 0.6, color)
		"battery_potion":
			# Lattina dell'energetico col fulmine.
			_draw_can(canvas, Vector2.ZERO, 0.6, color)
		"potion_slots":
			# Kit medico, tanica e lattina, e un + sopra: se ne portano di più.
			_draw_medkit(canvas, Vector2(-0.52, 0.25), 0.26, color_of("potion_heal"))
			_draw_jerrycan(canvas, Vector2(0, 0.25), 0.26, color_of("mana_restore"))
			_draw_can(canvas, Vector2(0.52, 0.25), 0.26, color_of("battery_potion"))
			_draw_plus(canvas, Vector2(0, -0.55), 0.18, color)
		"potion_heal":
			# Kit medico con un + accanto: cura di più.
			_draw_medkit(canvas, Vector2(-0.15, 0.1), 0.45, color)
			_draw_plus(canvas, Vector2(0.45, -0.4), 0.22, Color(1, 1, 1, 0.9))
		"mana_restore":
			# Tanica con un + accanto: ridà più carburante.
			_draw_jerrycan(canvas, Vector2(-0.15, 0.1), 0.45, color)
			_draw_plus(canvas, Vector2(0.45, -0.4), 0.22, Color(1, 1, 1, 0.9))
		"choice":
			# Tre carte a ventaglio con una quarta che si aggiunge.
			for k in 4:
				var angle := -0.45 + k * 0.3
				var card := PackedVector2Array()
				for corner: Vector2 in [Vector2(-0.18, -0.3), Vector2(0.18, -0.3), Vector2(0.18, 0.3), Vector2(-0.18, 0.3)]:
					card.append((corner + Vector2(0, -0.25)).rotated(angle) + Vector2(0, 0.25))
				canvas.draw_colored_polygon(card, color if k == 3 else color.darkened(0.45))
		"shield":
			# Scudo antisommossa con una freccia che gira: ricarica più rapida.
			canvas.draw_rect(Rect2(-0.45, -0.6, 0.9, 1.2), color)
			canvas.draw_rect(Rect2(-0.3, -0.45, 0.6, 0.18), Color(0.15, 0.2, 0.28))
			canvas.draw_arc(Vector2(0, 0.2), 0.22, -PI * 0.8, PI * 0.6, 12, Color(0.1, 0.15, 0.25), 0.08)
		"battery":
			# Fulmine verde, come accanto alla barra della batteria.
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(0.15, -0.65), Vector2(-0.4, 0.08), Vector2(0.0, 0.08),
					Vector2(-0.15, 0.65), Vector2(0.4, -0.08), Vector2(0.0, -0.08)]), color)
		"run":
			# Freccia con le linee della velocità.
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(0.6, 0), Vector2(0.1, -0.4), Vector2(0.1, 0.4)]), color)
			for k in 3:
				var y := -0.25 + k * 0.25
				canvas.draw_line(Vector2(-0.6 + k * 0.1, y), Vector2(0.05, y), color, 0.09)
		"empowered":
			# Aura dorata: cerchio pieno con raggi.
			for k in 8:
				var direction := Vector2.from_angle(TAU * k / 8.0)
				canvas.draw_line(direction * 0.45, direction * 0.75, color, 0.1)
			canvas.draw_circle(Vector2.ZERO, 0.35, color)
		"mana":
			# Goccia di carburante.
			canvas.draw_circle(Vector2(0, 0.18), 0.38, color)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-0.33, 0.0), Vector2(0.33, 0.0), Vector2(0, -0.62)]), color)
			canvas.draw_circle(Vector2(-0.12, 0.1), 0.1, Color(1, 1, 1, 0.6))
		"spell":
			# Missile in volo, in diagonale, con il fumo dietro.
			for k in 3:
				canvas.draw_circle(Vector2(-0.5 + k * 0.14, 0.5 - k * 0.14), 0.1 + k * 0.04, Color(0.6, 0.6, 0.6, 0.35 + 0.15 * k))
			canvas.draw_set_transform(center + Vector2(0.1, -0.1) * side / 2.0, -PI / 4.0, Vector2.ONE * side / 2.0)
			canvas.draw_rect(Rect2(-0.4, -0.13, 0.65, 0.26), color)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(0.25, -0.13), Vector2(0.55, 0.0), Vector2(0.25, 0.13)]), Color(0.8, 0.22, 0.15))
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-0.4, -0.13), Vector2(-0.25, -0.13), Vector2(-0.5, -0.32)]), color.darkened(0.3))
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-0.4, 0.13), Vector2(-0.25, 0.13), Vector2(-0.5, 0.32)]), color.darkened(0.3))
			canvas.draw_circle(Vector2(-0.48, 0.0), 0.1, Color(1.0, 0.6, 0.2))
		"torch":
			# Torcia elettrica accesa, col fascio di luce.
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(0.05, -0.12), Vector2(0.7, -0.45), Vector2(0.7, 0.45), Vector2(0.05, 0.12)]), Color(color, 0.35))
			canvas.draw_rect(Rect2(-0.6, -0.12, 0.65, 0.24), Color(0.2, 0.2, 0.22))
			canvas.draw_rect(Rect2(-0.05, -0.17, 0.12, 0.34), Color(0.35, 0.35, 0.38))
			canvas.draw_circle(Vector2(0.08, 0.0), 0.1, color)
		"bag":
			# Zaino: sacca con la patta e la fibbia.
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-0.5, -0.25), Vector2(0.5, -0.25), Vector2(0.6, 0.6), Vector2(-0.6, 0.6)]), color)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-0.5, -0.25), Vector2(0.5, -0.25), Vector2(0.35, 0.15), Vector2(-0.35, 0.15)]), color.darkened(0.25))
			canvas.draw_arc(Vector2(0, -0.3), 0.25, PI, TAU, 10, color.darkened(0.3), 0.1)
			canvas.draw_rect(Rect2(-0.08, 0.05, 0.16, 0.16), Color(0.9, 0.8, 0.4))
		"bubble":
			# Piastre di kevlar dello scudo attivo.
			var plates := PackedVector2Array()
			for k in 7:
				plates.append(Vector2.from_angle(TAU * k / 6.0 + PI / 6.0) * 0.62)
			canvas.draw_colored_polygon(plates, Color(color, 0.3))
			canvas.draw_polyline(plates, color, 0.1)
	canvas.draw_set_transform(Vector2.ZERO)


## Kit medico (valigetta bianca con la croce del colore dato), largo
## 2 * half, centrato in at.
static func _draw_medkit(canvas: CanvasItem, at: Vector2, half: float, color: Color) -> void:
	canvas.draw_rect(Rect2(at - Vector2(half, half * 0.75), Vector2(half * 2.0, half * 1.5)), Color(0.95, 0.95, 0.92))
	canvas.draw_arc(at - Vector2(0, half * 0.75), half * 0.35, PI, TAU, 8, Color(0.6, 0.6, 0.6), half * 0.15)
	canvas.draw_rect(Rect2(at - Vector2(half * 0.5, half * 0.15), Vector2(half, half * 0.3)), color)
	canvas.draw_rect(Rect2(at - Vector2(half * 0.15, half * 0.5), Vector2(half * 0.3, half)), color)


## Tanica di carburante del colore dato, larga 2 * half, centrata in at.
static func _draw_jerrycan(canvas: CanvasItem, at: Vector2, half: float, color: Color) -> void:
	canvas.draw_rect(Rect2(at - Vector2(half * 0.8, half), Vector2(half * 1.6, half * 2.0)), color)
	canvas.draw_line(at + Vector2(-half * 0.8, -half), at + Vector2(half * 0.8, half), color.darkened(0.35), half * 0.15)
	canvas.draw_line(at + Vector2(half * 0.4, -half), at + Vector2(half * 0.8, -half * 1.4), Color(0.3, 0.3, 0.3), half * 0.25)


## Lattina dell'energetico (colore dato) col fulmine giallo.
static func _draw_can(canvas: CanvasItem, at: Vector2, half: float, color: Color) -> void:
	canvas.draw_rect(Rect2(at - Vector2(half * 0.55, half), Vector2(half * 1.1, half * 2.0)), color)
	canvas.draw_rect(Rect2(at - Vector2(half * 0.55, half), Vector2(half * 1.1, half * 0.2)), Color(0.8, 0.8, 0.8))
	canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(half * 0.15, -half * 0.6), at + Vector2(-half * 0.3, half * 0.1),
			at + Vector2(0, half * 0.1), at + Vector2(-half * 0.15, half * 0.7), at + Vector2(half * 0.3, -half * 0.1), at + Vector2(0, -half * 0.1)]), Color(1, 1, 0.4))


## Segno + di metà larghezza half, centrato in at.
static func _draw_plus(canvas: CanvasItem, at: Vector2, half: float, color: Color) -> void:
	canvas.draw_line(at - Vector2(half, 0), at + Vector2(half, 0), color, half * 0.55)
	canvas.draw_line(at - Vector2(0, half), at + Vector2(0, half), color, half * 0.55)
