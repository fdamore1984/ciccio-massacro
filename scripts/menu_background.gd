extends Control
## Sfondo del menù iniziale nello stile del sito, in versione cupa: sfumatura
## radiale dal rosso scuro al nero, retino a puntini da fumetto, schizzi di
## sangue, grana leggera e, in basso, Ciccio e un punk disegnati col contorno
## nero.

## Retino: distanza fra i puntini e loro raggio.
const DOT_STEP := 12
const DOT_RADIUS := 2.2
const COLOR_DOT := Color(0, 0, 0, 0.35)
const COLOR_BLOOD := Color("b3121f")
const COLOR_PUNK := Color("f03a3a")
## Schizzi di sangue: centro (in frazioni dello schermo) e grandezza.
const SPLATS := [[Vector2(0.9, 0.17), 46.0], [Vector2(0.08, 0.12), 30.0], [Vector2(0.72, 0.88), 22.0]]

var _gradient := GradientTexture2D.new()
var _grain := UiStyle.grain_texture()
var _dots := _dot_texture()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([UiStyle.BACK_LIGHT, UiStyle.BACK, UiStyle.BACK_DARK])
	_gradient.gradient = gradient
	_gradient.fill = GradientTexture2D.FILL_RADIAL
	_gradient.fill_from = Vector2(0.5, 0.3)
	_gradient.fill_to = Vector2(1.2, 1.1)
	resized.connect(queue_redraw)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_texture_rect(_gradient, rect, false)
	draw_texture_rect(_dots, rect, true)
	for splat: Array in SPLATS:
		_draw_splat(size * (splat[0] as Vector2), splat[1])
	_draw_ciccio(Vector2(size.x - 150.0, size.y - 120.0), 56.0, -0.14)
	_draw_punk(Vector2(150.0, size.y - 230.0), 40.0, 0.2)
	draw_texture_rect(_grain, rect, true)


## Puntino del retino, da ripetere su tutto lo schermo.
func _dot_texture() -> ImageTexture:
	var image := Image.create(DOT_STEP, DOT_STEP, false, Image.FORMAT_RGBA8)
	var center := Vector2(DOT_STEP, DOT_STEP) / 2.0
	for y in DOT_STEP:
		for x in DOT_STEP:
			var inside := clampf(DOT_RADIUS + 0.5 - Vector2(x + 0.5, y + 0.5).distance_to(center), 0.0, 1.0)
			image.set_pixel(x, y, Color(COLOR_DOT, COLOR_DOT.a * inside))
	return ImageTexture.create_from_image(image)


## Schizzo: macchia a petali irregolari col contorno nero e due gocce.
func _draw_splat(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for k in 16:
		var reach := radius * (1.0 if k % 2 == 0 else 0.68) * (1.0 + 0.18 * sin(k * 2.3))
		points.append(center + Vector2.from_angle(TAU * k / 16.0) * reach)
	_ink_polygon(points, COLOR_BLOOD, 4.0)
	_ink_disc(center + Vector2(-radius * 1.5, -radius * 0.6), radius * 0.16, COLOR_BLOOD, 3.0)
	_ink_disc(center + Vector2(radius * 1.3, radius * 1.1), radius * 0.12, COLOR_BLOOD, 3.0)


## Ciccio: testa rosa con la cresta nera, gli occhi grandi e un livido.
func _draw_ciccio(center: Vector2, radius: float, angle: float) -> void:
	draw_set_transform(center, angle)
	var hair := PackedVector2Array([Vector2(-radius * 0.7, -radius * 0.45)])
	for k in 7:
		var x := -radius * 0.7 + radius * 1.4 * k / 6.0
		hair.append(Vector2(x, -radius * (1.45 if k % 2 == 0 else 1.1)))
	hair.append(Vector2(radius * 0.7, -radius * 0.45))
	_ink_polygon(hair, UiStyle.INK, 0.0)
	_ink_disc(Vector2.ZERO, radius, Player.COLOR_BODY)
	draw_arc(Vector2.ZERO, radius * 0.72, PI * 1.1, PI * 1.45, 12, Player.COLOR_BODY.lightened(0.45), 6.0, true)
	_draw_eyes(Vector2(0, -radius * 0.05), radius / 32.0, false)
	Shapes.disc(self, Vector2(radius * 0.45, radius * 0.5), radius * 0.13, COLOR_BLOOD)
	draw_arc(Vector2(0, radius * 0.35), radius * 0.26, PI * 0.2, PI * 0.8, 10, UiStyle.INK, 4.0, true)
	draw_set_transform(Vector2.ZERO)


## Punk rosso con la cresta, arrabbiato.
func _draw_punk(center: Vector2, radius: float, angle: float) -> void:
	draw_set_transform(center, angle)
	var crest := PackedVector2Array([Vector2(-radius * 0.35, -radius * 0.8)])
	for k in 5:
		crest.append(Vector2(-radius * 0.3 + radius * 0.6 * k / 4.0, -radius * (1.55 if k % 2 == 0 else 1.15)))
	crest.append(Vector2(radius * 0.35, -radius * 0.8))
	_ink_polygon(crest, UiStyle.INK, 0.0)
	_ink_disc(Vector2.ZERO, radius, COLOR_PUNK)
	_draw_eyes(Vector2(0, -radius * 0.05), radius / 40.0, true)
	draw_set_transform(Vector2.ZERO)


## Occhi bianchi ovali con le pupille, come quelli di Ufotizio; arrabbiati
## con le sopracciglia storte.
func _draw_eyes(center: Vector2, scale_factor: float, angry: bool) -> void:
	for side: float in [-1.0, 1.0]:
		var eye := center + Vector2(side * 10.0, 0) * scale_factor
		_ink_polygon(_ellipse(eye, Vector2(7.5, 9.5) * scale_factor), Color.WHITE, 3.0)
		Shapes.disc(self, eye + Vector2(2.0, 2.0) * scale_factor, 3.6 * scale_factor, UiStyle.INK)
		if angry:
			draw_line(eye + Vector2(side * 9.0, -13.0) * scale_factor, eye + Vector2(-side * 5.0, -7.0) * scale_factor, UiStyle.INK, 4.0 * scale_factor, true)


func _ellipse(center: Vector2, radii: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for k in 24:
		points.append(center + Vector2.from_angle(TAU * k / 24.0) * radii)
	return points


func _ink_disc(center: Vector2, radius: float, color: Color, outline := 5.0) -> void:
	Shapes.disc(self, center, radius + outline, UiStyle.INK)
	Shapes.disc(self, center, radius, color)


## Poligono pieno col contorno nero (il poligono allargato, a spigoli tondi).
func _ink_polygon(points: PackedVector2Array, color: Color, outline := 5.0) -> void:
	if outline > 0.0:
		for grown in Geometry2D.offset_polygon(points, outline, Geometry2D.JOIN_ROUND):
			draw_colored_polygon(grown, UiStyle.INK)
	draw_colored_polygon(points, color)
