class_name Flashlight
extends Node2D
## Luce della torcia elettrica del giocatore: fasci a cono nella direzione
## dello sguardo, senza alone attorno al personaggio (vedi
## LightTexture.get_cone_texture): uno ampio e profondo e, attorno, uno
## ancora più largo e lungo ma molto meno luminoso ("beams" della voce
## "flashlight" di data/world.json). I coni sono pensati in pianta e questo
## nodo li schiaccia a metà in verticale, come i cerchi a terra della
## prospettiva isometrica: puntati in orizzontale sono lunghi e stretti,
## verso l'alto o il basso dello schermo corti e larghi, come fasci stesi
## sul terreno. Il nodo va messo a terra sotto il personaggio (Player lo
## sposta).
##
## Serve solo al buio: con abbastanza luce (di giorno, all'alba, al
## tramonto) i fasci non illuminano nulla; si accendono a poco a poco mentre
## il buio passa da "dark_from" a "dark_full" (vedi DayNight.darkness), e al
## buio pieno il fascio principale illumina quanto la luce del giorno.
##
## La luce non passa attraverso i muri: ogni fascio è fatto di due luci con
## le ombre, una per il pavimento (che fa ombra con la base e la cima dei
## blocchi) e una per tutto il resto (solo con la cima), vedi World.

const DATA := preload("res://data/world.json")
## La prospettiva isometrica: il terreno è schiacciato a metà in verticale.
const GROUND_SQUASH := 0.5

## Accesa o spenta.
var enabled := false:
	set(value):
		enabled = value
		for light in _lights:
			light.enabled = value

var _settings: Dictionary = DATA.data["flashlight"]
## Luci dei fasci e loro energia piena.
var _lights: Array[PointLight2D] = []
var _energies: Array[float] = []


func _init() -> void:
	scale = Vector2(1.0, GROUND_SQUASH)
	for beam: Dictionary in _settings["beams"]:
		for floor_layer: bool in [true, false]:
			var light := PointLight2D.new()
			light.texture = LightTexture.get_cone_texture(float(beam["angle"]))
			light.texture_scale = float(beam["range"]) / (LightTexture.CONE_SIZE / 2.0)
			light.color = World._color(_settings["color"])
			light.shadow_enabled = true
			light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
			light.shadow_filter_smooth = 2.0
			if floor_layer:
				light.range_item_cull_mask = World.LIGHT_FLOOR
				light.shadow_item_cull_mask = World.OCCLUDER_BASE | World.OCCLUDER_TOP
			else:
				light.range_item_cull_mask = ~World.LIGHT_FLOOR & 0xFFFFF
				light.shadow_item_cull_mask = World.OCCLUDER_TOP
			light.enabled = enabled
			add_child(light)
			_lights.append(light)
			_energies.append(float(beam["energy"]))


## Quanto illuminano adesso i fasci accesi, da 0 (c'è luce: niente) a 1
## (buio pieno: come di giorno).
func strength() -> float:
	if not enabled:
		return 0.0
	var dark := DayNight.current.darkness() if DayNight.current else 1.0
	return smoothstep(float(_settings["dark_from"]), float(_settings["dark_full"]), dark)


func _process(_delta: float) -> void:
	if enabled:
		var power := strength()
		for k in _lights.size():
			_lights[k].energy = _energies[k] * power
			_lights[k].visible = power > 0.001


## Punta i fasci nella direzione dello sguardo (sullo schermo): in pianta
## la componente verticale è il doppio.
func aim(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		for light in _lights:
			light.rotation = Vector2(direction.x, direction.y / GROUND_SQUASH).angle()
