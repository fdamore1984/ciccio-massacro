class_name Flashlight
extends Node2D
## Luce della torcia elettrica del giocatore: niente fascio a cono, solo un
## alone tondo attorno al personaggio, steso a terra nella prospettiva
## isometrica (la texture di LightTexture è un'ellisse larga il doppio che
## alta). Il nodo va messo a terra sotto il personaggio (Player lo sposta).

const COLOR := Color(0.92, 0.95, 1.0)
const ENERGY := 1.1
## Raggio dell'alone in pixel di terreno (in orizzontale).
const RANGE := 300.0

## Accesa o spenta.
var enabled := false:
	set(value):
		enabled = value
		_light.enabled = value

var _light := PointLight2D.new()


func _init() -> void:
	_light.texture = LightTexture.get_texture()
	_light.texture_scale = RANGE / (LightTexture.SIZE / 2.0)
	_light.color = COLOR
	_light.energy = ENERGY
	_light.enabled = enabled
	add_child(_light)
