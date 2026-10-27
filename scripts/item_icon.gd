class_name ItemIcon
extends Control
## Icona geometrica di un oggetto (data/items.json), disegnata in codice in
## attesa delle icone definitive. Usata nell'inventario; draw_item disegna
## la stessa icona anche nel mondo (oggetti a terra).

@export var item_id := "":
	set(value):
		item_id = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if item_id == "":
		return
	var side := minf(size.x, size.y)
	draw_item(self, size / 2.0, side, item_id)


## Disegna l'oggetto centrato in center, grande circa side pixel.
static func draw_item(canvas: CanvasItem, center: Vector2, side: float, id: String) -> void:
	var color := Items.color(id)
	var s := side / 2.0
	match Items.category(id):
		"gold":
			# Rottame: un dado esagonale col foro.
			var nut := PackedVector2Array()
			for k in 6:
				nut.append(center + Vector2.from_angle(TAU * k / 6.0) * s * 0.7)
			canvas.draw_colored_polygon(nut, color.darkened(0.2))
			canvas.draw_circle(center, s * 0.5, color)
			canvas.draw_circle(center, s * 0.25, color.darkened(0.55))
		"weapon":
			# Catena e barra per la motosega.
			BodyParts.draw_chainsaw(canvas, center + Vector2(-s * 0.6, s * 0.6), -PI / 4.0, s * 1.7, maxf(s * 0.16, 2.0), color.lightened(0.3))
		"armor":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(-s * 0.7, -s * 0.6), center + Vector2(-s * 0.25, -s * 0.7), center + Vector2(0, -s * 0.5),
				center + Vector2(s * 0.25, -s * 0.7), center + Vector2(s * 0.7, -s * 0.6), center + Vector2(s * 0.55, s * 0.7),
				center + Vector2(-s * 0.55, s * 0.7),
			]), color)
			canvas.draw_line(center + Vector2(0, -s * 0.45), center + Vector2(0, s * 0.65), color.darkened(0.3), maxf(s * 0.08, 1.0))
			canvas.draw_line(center + Vector2(-s * 0.5, s * 0.1), center + Vector2(s * 0.5, s * 0.1), color.darkened(0.3), maxf(s * 0.08, 1.0))
		"boots":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(-s * 0.3, -s * 0.7), center + Vector2(s * 0.15, -s * 0.7), center + Vector2(s * 0.15, s * 0.2),
				center + Vector2(s * 0.7, s * 0.35), center + Vector2(s * 0.7, s * 0.65), center + Vector2(-s * 0.3, s * 0.65),
			]), color)
			canvas.draw_line(center + Vector2(-s * 0.3, s * 0.45), center + Vector2(s * 0.7, s * 0.45), color.darkened(0.35), maxf(s * 0.1, 1.0))
		"amulet":
			# Serbatoio di carburante con la maniglia.
			canvas.draw_rect(Rect2(center - Vector2(s * 0.5, s * 0.45), Vector2(s * 1.0, s * 1.15)), color)
			canvas.draw_line(center + Vector2(-s * 0.5, -s * 0.45), center + Vector2(s * 0.5, s * 0.7), color.darkened(0.3), maxf(s * 0.08, 1.0))
			canvas.draw_rect(Rect2(center + Vector2(-s * 0.3, -s * 0.7), Vector2(s * 0.45, s * 0.2)), color.darkened(0.4))
			canvas.draw_line(center + Vector2(s * 0.3, -s * 0.45), center + Vector2(s * 0.55, -s * 0.75), Color(0.3, 0.3, 0.3), maxf(s * 0.12, 1.0))
		"ring":
			# Mirino: cerchio con il reticolo.
			canvas.draw_arc(center, s * 0.55, 0.0, TAU, 24, Color(0.25, 0.25, 0.27), maxf(s * 0.18, 1.5))
			canvas.draw_circle(center, s * 0.42, Color(color, 0.35))
			canvas.draw_line(center - Vector2(s * 0.42, 0), center + Vector2(s * 0.42, 0), color, maxf(s * 0.06, 1.0))
			canvas.draw_line(center - Vector2(0, s * 0.42), center + Vector2(0, s * 0.42), color, maxf(s * 0.06, 1.0))
			canvas.draw_circle(center, s * 0.08, Color(1.0, 0.2, 0.15))
		"book":
			# Manuale: copertina con il nastro adesivo e un segno.
			canvas.draw_rect(Rect2(center - Vector2(s * 0.6, s * 0.7), Vector2(s * 1.2, s * 1.4)), color)
			canvas.draw_rect(Rect2(center + Vector2(s * 0.45, -s * 0.62), Vector2(s * 0.12, s * 1.24)), Color(0.95, 0.92, 0.8))
			canvas.draw_rect(Rect2(center + Vector2(-s * 0.6, -s * 0.15), Vector2(s * 1.2, s * 0.22)), Color(0.75, 0.72, 0.6))
			canvas.draw_line(center + Vector2(-s * 0.3, -s * 0.4), center + Vector2(s * 0.2, -s * 0.4), color.lightened(0.5), maxf(s * 0.08, 1.0))
		"potion":
			draw_supply(canvas, center, s, id, color)


## Scorte: kit medico (cura), tanica (carburante), lattina energetica
## (batteria); quelle che fanno più cose (kit di sopravvivenza) sono una
## borsa con la croce.
static func draw_supply(canvas: CanvasItem, center: Vector2, s: float, id: String, color: Color) -> void:
	var heal := Items.stat(id, "heal") > 0.0
	var fuel := Items.stat(id, "restore_mana") > 0.0
	if heal and fuel:
		canvas.draw_rect(Rect2(center - Vector2(s * 0.7, s * 0.5), Vector2(s * 1.4, s * 1.1)), color)
		canvas.draw_arc(center + Vector2(0, -s * 0.5), s * 0.3, PI, TAU, 10, color.darkened(0.4), maxf(s * 0.1, 1.0))
		_draw_cross(canvas, center + Vector2(0, s * 0.05), s * 0.3, Color(0.95, 0.95, 0.9))
	elif heal:
		canvas.draw_rect(Rect2(center - Vector2(s * 0.7, s * 0.5), Vector2(s * 1.4, s * 1.0)), Color(0.95, 0.95, 0.92))
		_draw_cross(canvas, center, s * 0.32, color)
	elif fuel:
		canvas.draw_rect(Rect2(center - Vector2(s * 0.5, s * 0.55), Vector2(s * 1.0, s * 1.25)), color)
		canvas.draw_line(center + Vector2(-s * 0.5, -s * 0.55), center + Vector2(s * 0.5, s * 0.7), color.darkened(0.35), maxf(s * 0.08, 1.0))
		canvas.draw_line(center + Vector2(s * 0.25, -s * 0.55), center + Vector2(s * 0.55, -s * 0.85), Color(0.3, 0.3, 0.3), maxf(s * 0.14, 1.0))
	else:
		canvas.draw_rect(Rect2(center - Vector2(s * 0.35, s * 0.65), Vector2(s * 0.7, s * 1.3)), color)
		canvas.draw_rect(Rect2(center - Vector2(s * 0.35, s * 0.65), Vector2(s * 0.7, s * 0.15)), Color(0.8, 0.8, 0.8))
		canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(s * 0.1, -s * 0.4), center + Vector2(-s * 0.18, s * 0.05),
				center + Vector2(0, s * 0.05), center + Vector2(-s * 0.1, s * 0.45), center + Vector2(s * 0.2, -s * 0.05), center + Vector2(0, -s * 0.05)]), Color(1, 1, 0.4))


static func _draw_cross(canvas: CanvasItem, center: Vector2, half: float, color: Color) -> void:
	canvas.draw_rect(Rect2(center - Vector2(half, half * 0.35), Vector2(half * 2.0, half * 0.7)), color)
	canvas.draw_rect(Rect2(center - Vector2(half * 0.35, half), Vector2(half * 0.7, half * 2.0)), color)
