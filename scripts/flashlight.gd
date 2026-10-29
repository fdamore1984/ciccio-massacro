class_name Flashlight
extends Node2D
## Luce della torcia elettrica del giocatore: un fascio a cono nella
## direzione dello sguardo, ampio e profondo, senza alone attorno al
## personaggio (vedi LightTexture.get_cone_texture). Il cono è pensato in pianta e questo nodo
## lo schiaccia a metà in verticale, come i cerchi a terra della
## prospettiva isometrica: puntato in orizzontale è lungo e stretto, verso
## l'alto o il basso dello schermo è corto e largo, come un fascio steso sul
## terreno. Il nodo va messo a terra sotto il personaggio (Player lo sposta).
##
## Serve solo al buio: con abbastanza luce (di giorno, all'alba, al
## tramonto) il fascio non illumina nulla; si accende a poco a poco mentre
## il buio passa da DARK_FROM a DARK_FULL (vedi DayNight.darkness), e al
## buio pieno illumina quanto la luce del giorno.

const COLOR := Color(0.95, 0.97, 1.0)
const ENERGY := 1.0
## Buio (0 giorno, 1 nero) in cui il fascio comincia a vedersi e in cui è pieno.
const DARK_FROM := 0.35
const DARK_FULL := 0.8
## Portata del fascio in pixel di terreno, in pianta.
const RANGE := 960.0
## La prospettiva isometrica: il terreno è schiacciato a metà in verticale.
const GROUND_SQUASH := 0.5

## Accesa o spenta.
var enabled := false:
	set(value):
		enabled = value
		_light.enabled = value

var _light := PointLight2D.new()


func _init() -> void:
	scale = Vector2(1.0, GROUND_SQUASH)
	_light.texture = LightTexture.get_cone_texture()
	_light.texture_scale = RANGE / (LightTexture.CONE_SIZE / 2.0)
	_light.color = COLOR
	_light.energy = ENERGY
	_light.enabled = enabled
	add_child(_light)


## Quanto illumina adesso il fascio acceso, da 0 (c'è luce: niente) a 1
## (buio pieno: come di giorno).
func strength() -> float:
	if not enabled:
		return 0.0
	var dark := DayNight.current.darkness() if DayNight.current else 1.0
	return smoothstep(DARK_FROM, DARK_FULL, dark)


func _process(_delta: float) -> void:
	if enabled:
		_light.energy = ENERGY * strength()
		_light.visible = _light.energy > 0.001


## Punta il fascio nella direzione dello sguardo (sullo schermo): in pianta
## la componente verticale è il doppio.
func aim(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		_light.rotation = Vector2(direction.x, direction.y / GROUND_SQUASH).angle()
