class_name MissionCrate
extends Node2D
## Cassa della missione "recupera la cassa" (vedi Missions e Game): una
## cassa militare verde con le strisce gialle e un fumogeno rosso acceso
## accanto, il cui fumo sale e si vede da lontano. Non prende luci, così si
## trova anche di notte. Si apre interagendo (vedi Game._find_interactable).

const SIZE := Vector2(46, 30)
const COLOR_CRATE := Color(0.33, 0.4, 0.25)
const COLOR_STRIPE := Color(0.95, 0.78, 0.2)
const COLOR_SMOKE := Color(0.95, 0.25, 0.15)

var _age := 0.0
var _lift := 0.0


func _ready() -> void:
	material = Enemy._unshaded_material()
	if World.current:
		_lift = World.current.elevation_at(position)


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()


func _draw() -> void:
	var base := Vector2(0, -_lift)
	Shapes.disc(self, base + Vector2(0, 4), 26.0, Shapes.SHADOW)
	# Fumo del fumogeno: sbuffi rossi che salgono, si allargano e svaniscono.
	for k in 7:
		var t := fposmod(_age * 0.45 + k / 7.0, 1.0)
		var at := base + Vector2(30 + sin(k * 1.7 + _age) * 6.0 + 18.0 * t, -10.0 - 150.0 * t)
		Shapes.disc(self, at, 6.0 + 16.0 * t, Color(COLOR_SMOKE, 0.5 * (1.0 - t)))
	Shapes.glow(self, base + Vector2(30, -6), 14.0 + 3.0 * sin(_age * 18.0), Color(1.0, 0.45, 0.2, 0.8))
	# La cassa: corpo, coperchio più chiaro e due strisce.
	var rect := Rect2(base + Vector2(-SIZE.x / 2.0, -SIZE.y), SIZE)
	draw_rect(rect.grow(3.0), Shapes.INK)
	draw_rect(rect, COLOR_CRATE)
	draw_rect(Rect2(rect.position, Vector2(SIZE.x, 7)), COLOR_CRATE.lightened(0.2))
	for x in [-14.0, 10.0]:
		draw_rect(Rect2(base + Vector2(x, -SIZE.y + 7), Vector2(5, SIZE.y - 7)), COLOR_STRIPE)
