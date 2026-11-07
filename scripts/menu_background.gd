extends Control
## Sfondo del menù iniziale nello stile del sito, in versione cupa: sfumatura
## radiale dal rosso scuro al nero, retino a puntini da fumetto, schizzi di
## sangue, grana leggera e, in basso a destra, Ciccio com'è nel gioco
## (disegnato con le stesse forme, vedi PlayerLook), ingrandito: urla con la
## motosega alzata.

## Retino: distanza fra i puntini e loro raggio.
const DOT_STEP := 12
const DOT_RADIUS := 2.2
const COLOR_DOT := Color(0, 0, 0, 0.35)
const COLOR_BLOOD := Color("b3121f")
## Ciccio: ingrandimento rispetto al gioco, posa e bocca spalancata.
const CICCIO_SCALE := 2.8
const CICCIO_FACING := Vector2(-0.38, 0.92)
const CICCIO_TILT := -0.08
const CICCIO_SCREAM := 0.85
const SAW_HAND := Vector2(26.0, -10.0)
const SAW_ANGLE := -1.15
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
	_draw_ciccio(Vector2(size.x - 200.0, size.y - 95.0))
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


## Ciccio com'è nel gioco (vedi Player._draw): la palla color pesca col
## contorno spesso, gli occhioni fusi, il boccone spalancato, braccia e
## gambe a linea nera e la motosega rossa alzata. feet: dove poggiano i piedi.
func _draw_ciccio(feet: Vector2) -> void:
	var zoom := Vector2(CICCIO_SCALE, CICCIO_SCALE)
	# Come in Player._draw: l'origine sta un po' sopra i piedi, le gambe
	# partono da lì e la palla è LEG_LENGTH più in alto.
	var origin := feet - Vector2(0, PlayerLook.RADIUS * 0.85).rotated(CICCIO_TILT) * CICCIO_SCALE
	draw_set_transform(origin, CICCIO_TILT, zoom)
	Shapes.disc(self, Vector2(0, PlayerLook.RADIUS * 0.8), PlayerLook.RADIUS * 0.9, Shapes.SHADOW)
	PlayerLook.draw_legs(self, -Player.LEG_LENGTH + PlayerLook.RADIUS * 0.62, PlayerLook.RADIUS * 0.85,
			Player.LEG_SPACING, 0.0, Vector2.ZERO, 0.0, CICCIO_FACING, false, 0.4)
	draw_set_transform(origin + Vector2(0, -Player.LEG_LENGTH).rotated(CICCIO_TILT) * CICCIO_SCALE, CICCIO_TILT, zoom)
	var look := PlayerLook.face(CICCIO_FACING)
	var hands := PlayerLook.saw_hands(SAW_HAND, SAW_ANGLE, Player.HEAVY_SAW_LENGTH, Player.SAW_WIDTH * 1.3)
	# Motosega alzata sopra la spalla: dietro alla palla, come nel gioco.
	PlayerLook.draw_arms(self, hands[0], hands[1])
	PlayerLook.draw_chainsaw(self, SAW_HAND, SAW_ANGLE, Player.HEAVY_SAW_LENGTH, Player.SAW_WIDTH * 1.3)
	PlayerLook.draw_glove(self, hands[0])
	PlayerLook.draw_glove(self, hands[1])
	PlayerLook.draw_ball(self, Player.COLOR_BODY)
	# Un po' di sangue addosso.
	Shapes.disc(self, Vector2(PlayerLook.RADIUS * 0.5, PlayerLook.RADIUS * 0.15), PlayerLook.RADIUS * 0.12, COLOR_BLOOD)
	Shapes.disc(self, Vector2(-PlayerLook.RADIUS * 0.62, -PlayerLook.RADIUS * 0.05), PlayerLook.RADIUS * 0.07, COLOR_BLOOD)
	PlayerLook.draw_grin(self, look, CICCIO_SCREAM)
	PlayerLook.draw_eyes(self, look, Player.COLOR_BODY)
	draw_set_transform(Vector2.ZERO)


func _ink_disc(center: Vector2, radius: float, color: Color, outline := 5.0) -> void:
	Shapes.disc(self, center, radius + outline, UiStyle.INK)
	Shapes.disc(self, center, radius, color)


## Poligono pieno col contorno nero (il poligono allargato, a spigoli tondi).
func _ink_polygon(points: PackedVector2Array, color: Color, outline := 5.0) -> void:
	if outline > 0.0:
		for grown in Geometry2D.offset_polygon(points, outline, Geometry2D.JOIN_ROUND):
			draw_colored_polygon(grown, UiStyle.INK)
	draw_colored_polygon(points, color)
