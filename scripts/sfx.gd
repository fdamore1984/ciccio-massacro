extends Node
## Effetti sonori (autoload "Sfx").
##
## Finché non ci sono file audio veri, i suoni vengono sintetizzati all'avvio
## con forme d'onda semplici. Per sostituirne uno basterà caricare il file
## al posto della sintesi nello stesso dizionario.

const MIX_RATE := 22050
const POOL_SIZE := 16
## Oltre questa distanza i suoni posizionali non si sentono più.
const MAX_DISTANCE := 1400.0
## Voci (versi brevi a onda quadra quando si è colpiti e abbattuti, vedi
## Voice): quante varianti di ciascuna e i lettori riservati ai versi di
## morte, che continuano anche dopo che il nemico morto è sparito.
const VOICES := {"pain": 4, "scream": 3}
const VOICE_POOL_SIZE := 6

var _streams := {}
var _pool: Array[AudioStreamPlayer2D] = []
var _next := 0
var _voice_pool: Array[AudioStreamPlayer2D] = []
var _next_voice := 0
var _ui_player := AudioStreamPlayer.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_sounds()
	for i in POOL_SIZE:
		var player := AudioStreamPlayer2D.new()
		player.max_distance = MAX_DISTANCE
		player.attenuation = 1.5
		add_child(player)
		_pool.append(player)
	for i in VOICE_POOL_SIZE:
		var player := AudioStreamPlayer2D.new()
		player.max_distance = MAX_DISTANCE
		player.attenuation = 1.5
		add_child(player)
		_voice_pool.append(player)
	add_child(_ui_player)


## Suono nel mondo di gioco, posizionato in at. Il tono varia di poco
## a ogni riproduzione, così i suoni ripetuti non stancano.
func play(sound: String, at: Vector2, pitch := 1.0, volume_db := 0.0) -> void:
	if not _streams.has(sound):
		return
	var player := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	player.stream = _streams[sound]
	player.global_position = at
	player.pitch_scale = pitch * randf_range(0.95, 1.05)
	player.volume_db = volume_db
	player.play()


## Una variante a caso di una voce (kind: "pain" o "scream", vedi VOICES).
func voice(kind: String) -> AudioStream:
	return _streams.get("%s_%d" % [kind, randi() % int(VOICES.get(kind, 1))])


## Voce nel mondo di gioco su un lettore riservato (vedi VOICE_POOL_SIZE):
## pitch è il tono della voce di chi la emette.
func play_voice(kind: String, at: Vector2, pitch := 1.0, volume_db := 0.0) -> void:
	var stream := voice(kind)
	if stream == null:
		return
	var player := _voice_pool[_next_voice]
	_next_voice = (_next_voice + 1) % VOICE_POOL_SIZE
	player.stream = stream
	player.global_position = at
	player.pitch_scale = pitch * randf_range(0.95, 1.05)
	player.volume_db = volume_db
	player.play()


## Suono dell'interfaccia, non posizionale.
func play_ui(sound: String) -> void:
	if not _streams.has(sound):
		return
	_ui_player.stream = _streams[sound]
	_ui_player.play()


func _build_sounds() -> void:
	# Personaggio: la motosega ronza a ogni colpo (dente di sega aspro con
	# il rumore della catena).
	_streams["swing"] = _render_filtered(0.22, Vector2(0.55, 0.3), func(t: float, d: float) -> float:
		var rev := _saw(lerpf(95.0, 150.0, t / d) * t) * 0.45 + _saw(lerpf(190.0, 300.0, t / d) * t) * 0.2
		return (rev + _noise() * 0.3) * (0.75 + 0.25 * sin(TAU * 38.0 * t)) * _env(t, d, 0.01))
	# La catena morde: un colpo sordo con il ringhio della motosega.
	_streams["hit"] = _render(0.2, func(t: float, d: float) -> float:
		var tone := sin(TAU * lerpf(150.0, 55.0, t / d) * t)
		var grind := _saw(lerpf(130.0, 80.0, t / d) * t) * (0.6 + 0.4 * sin(TAU * 55.0 * t))
		return (tone * 0.6 + grind * 0.35 + _noise() * 0.45 * _env(t, 0.05, 0.0)) * _env(t, d, 0.003))
	_streams["dodge"] = _render_filtered(0.22, Vector2(0.12, 0.45), func(t: float, d: float) -> float:
		return _noise() * sin(PI * t / d) * 0.45)
	# Metallo contro metallo (motosega contro mazza o tubo).
	_streams["block"] = _render(0.25, func(t: float, d: float) -> float:
		var metal := sin(TAU * 1200.0 * t) + sin(TAU * 1870.0 * t) * 0.6 + sin(TAU * 2650.0 * t) * 0.4
		return metal * 0.3 * exp(-t * 18.0))
	_streams["perfect"] = _render(0.55, func(t: float, _d: float) -> float:
		var chime := sin(TAU * 880.0 * t) + sin(TAU * 1320.0 * t) * 0.7
		if t > 0.08:
			chime += sin(TAU * 1760.0 * t) * exp(-(t - 0.08) * 6.0)
		return chime * 0.25 * exp(-t * 5.0))
	_streams["hurt"] = _render(0.25, func(t: float, d: float) -> float:
		var square := signf(sin(TAU * lerpf(220.0, 110.0, t / d) * t))
		return (square * 0.35 + _noise() * 0.25) * _env(t, d, 0.005))
	_streams["death"] = _render(0.7, func(t: float, d: float) -> float:
		return signf(sin(TAU * lerpf(320.0, 50.0, t / d) * t)) * 0.3 * _env(t, d, 0.01))
	_streams["level_up"] = _render(0.5, func(t: float, _d: float) -> float:
		var notes := [523.25, 659.25, 783.99, 1046.5]
		var index := mini(int(t / 0.09), notes.size() - 1)
		var local := t - index * 0.09
		return _triangle(notes[index] * t) * 0.4 * exp(-local * (4.0 if index == 3 else 12.0)))
	# Colpo potente: la motosega va su di giri al rilascio, con un attacco secco.
	_streams["heavy_swing"] = _render_filtered(0.4, Vector2(0.5, 0.15), func(t: float, d: float) -> float:
		var rev := _saw(lerpf(110.0, 220.0, minf(t / 0.15, 1.0)) * t) * 0.5
		var rumble := sin(TAU * lerpf(90.0, 50.0, t / d) * t) * 0.35
		return (_noise() * 0.35 + rev + rumble) * (0.8 + 0.2 * sin(TAU * 45.0 * t)) * _env(t, d, 0.008))
	# Kit medico: la cerniera della borsa e un "bip" dello stimolante.
	_streams["potion"] = _render_filtered(0.45, Vector2(0.6, 0.6), func(t: float, d: float) -> float:
		var zip := _noise() * 0.35 * (0.5 + 0.5 * signf(sin(TAU * 60.0 * t))) * (1.0 if t < 0.25 else 0.0)
		var beep := sin(TAU * 1400.0 * t) * 0.2 if t > 0.3 else 0.0
		return (zip + beep) * _env(t, d, 0.005))
	# Scudo: le piastre di kevlar si agganciano con due scatti metallici.
	_streams["shield_up"] = _render(0.35, func(t: float, _d: float) -> float:
		var local := fmod(t, 0.16)
		var clack := (sin(TAU * 900.0 * t) * 0.4 + _noise() * 0.5) * exp(-local * 45.0)
		return clack * 0.5)
	_streams["shield_break"] = _render(0.35, func(t: float, d: float) -> float:
		var glass := sin(TAU * 1800.0 * t) * 0.3 + sin(TAU * 2700.0 * t) * 0.2
		return (glass + _noise() * 0.35) * _env(t, d, 0.002) * exp(-t * 6.0))
	_streams["jump"] = _render(0.18, func(t: float, d: float) -> float:
		return _triangle(lerpf(300.0, 700.0, t / d) * t) * 0.3 * _env(t, d, 0.005))
	_streams["slide"] = _render_filtered(0.4, Vector2(0.25, 0.08), func(t: float, d: float) -> float:
		return _noise() * 0.5 * _env(t, d, 0.02))
	_streams["xp"] = _render(0.08, func(t: float, d: float) -> float:
		return sin(TAU * lerpf(1200.0, 1600.0, t / d) * t) * 0.25 * _env(t, d, 0.005))
	_streams["charge_full"] = _render(0.25, func(t: float, d: float) -> float:
		return (sin(TAU * 1500.0 * t) + sin(TAU * 2250.0 * t) * 0.5) * 0.18 * _env(t, d, 0.003))
	# Tanica: il carburante gorgoglia nel serbatoio.
	_streams["mana_potion"] = _render_filtered(0.55, Vector2(0.25, 0.25), func(t: float, d: float) -> float:
		var glug := sin(TAU * (140.0 + 90.0 * fmod(t * 7.0, 1.0)) * t) * 0.5
		return (glug + _noise() * 0.3) * (0.5 + 0.5 * absf(sin(TAU * 7.0 * t))) * sin(PI * t / d))
	_streams["battery_potion"] = _render(0.4, func(t: float, d: float) -> float:
		# Energetico: la lattina si apre ("pssst") e un tono che sale svelto.
		if t < 0.08:
			return _noise() * 0.4 * (1.0 - t / 0.08)
		var rise := _triangle(lerpf(350.0, 900.0, t / d) * t) * 0.3
		return rise * (0.6 + 0.4 * absf(sin(TAU * 12.0 * t))) * sin(PI * t / d))
	# Bazooka: lo scoppio della partenza e il razzo che sibila via.
	_streams["missile_launch"] = _render_filtered(0.6, Vector2(0.6, 0.15), func(t: float, d: float) -> float:
		var pop := (_noise() * 0.9 + sin(TAU * 70.0 * t) * 0.6) * exp(-t * 30.0)
		var hiss := _noise() * 0.35 * sin(PI * t / d)
		return pop + hiss * _env(t, d, 0.05))
	# Esplosione del missile: botto forte, rombo basso e detriti che ricadono.
	_streams["explosion"] = _render_filtered(1.0, Vector2(0.7, 0.03), func(t: float, d: float) -> float:
		var boom := sin(TAU * lerpf(90.0, 28.0, t / d) * t) * 0.8 * exp(-t * 4.0)
		var debris := _noise() * 0.25 * absf(sin(TAU * 13.0 * t)) * (1.0 if t > 0.25 else 0.0)
		return clampf((_noise() * 0.9 * exp(-t * 6.0) + boom + debris) * 1.3, -1.0, 1.0) * _env(t, d, 0.002))
	# Impatto a terra (attacchi a terra, salto dei nemici).
	_streams["impact"] = _render_filtered(0.5, Vector2(0.5, 0.05), func(t: float, d: float) -> float:
		var boom := sin(TAU * lerpf(110.0, 40.0, t / d) * t) * 0.6
		return (_noise() * 0.7 + boom) * _env(t, d, 0.004))
	# Oggetti: clic dell'interruttore della torcia elettrica.
	_streams["torch"] = _render(0.06, func(t: float, d: float) -> float:
		return (sin(TAU * 2200.0 * t) * 0.3 + _noise() * 0.3) * exp(-t * 90.0) * _env(t, d, 0.001))
	_streams["chest_open"] = _render(0.5, func(t: float, d: float) -> float:
		# Cigolio del coperchio della cassa e poi un accordo.
		var creak := signf(sin(TAU * (180.0 + 60.0 * sin(TAU * 9.0 * t)) * t)) * 0.12 * exp(-t * 8.0)
		var chord := 0.0
		if t > 0.15:
			var local := t - 0.15
			chord = (sin(TAU * 660.0 * t) + sin(TAU * 880.0 * t) + sin(TAU * 1100.0 * t)) * 0.12 * exp(-local * 5.0)
		return (creak + chord) * _env(t, d, 0.005))
	# Porta dell'edificio: cigolio dei cardini e il tonfo dell'anta.
	_streams["door"] = _render(0.6, func(t: float, d: float) -> float:
		var creak := signf(sin(TAU * (240.0 + 90.0 * sin(TAU * 6.0 * t)) * t)) * 0.12 * (1.0 if t < 0.4 else 0.0)
		var thud := (sin(TAU * 70.0 * t) * 0.6 + _noise() * 0.3) * exp(-maxf(t - 0.4, 0.0) * 25.0) * (1.0 if t >= 0.4 else 0.0)
		return (creak + thud) * _env(t, d, 0.01))
	_streams["pickup"] = _render(0.15, func(t: float, d: float) -> float:
		return _triangle(lerpf(700.0, 1300.0, t / d) * t) * 0.3 * _env(t, d, 0.003))
	# Risata di Ciccio: cinque "oh" grassi e tondi, sempre un po' più bassi.
	_streams["giggle"] = _render(0.85, func(t: float, _d: float) -> float:
		var syllable := fmod(t, 0.16)
		var index := floorf(t / 0.16)
		var pitch := 300.0 - index * 22.0 + 25.0 * sin(TAU * 11.0 * t)
		var env := exp(-syllable * 20.0) * (1.0 - exp(-syllable * 220.0))
		return (sin(TAU * pitch * t) * 0.55 + sin(TAU * pitch * 2.0 * t) * 0.3 + _noise() * 0.18 * exp(-syllable * 70.0)) * env * 0.4)
	_streams["coin"] = _render(0.2, func(t: float, _d: float) -> float:
		var note := 1800.0 if t < 0.06 else 2400.0
		return sin(TAU * note * t) * 0.25 * exp(-fmod(t, 0.06) * 25.0))
	# Nemici
	_streams["enemy_windup"] = _render(0.5, func(t: float, d: float) -> float:
		return _triangle(lerpf(180.0, 420.0, t / d) * t) * 0.25 * _env(t, d, 0.05))
	_streams["enemy_strike"] = _render_filtered(0.2, Vector2(0.3, 0.08), func(t: float, d: float) -> float:
		return _noise() * _env(t, d, 0.01) * 0.6)
	# Colpo di pistola o di fucile: schiocco secco con una breve coda.
	_streams["gunshot"] = _render_filtered(0.3, Vector2(0.9, 0.1), func(t: float, d: float) -> float:
		var crack := _noise() * exp(-t * 35.0)
		var body := sin(TAU * lerpf(220.0, 80.0, t / d) * t) * 0.5 * exp(-t * 18.0)
		return clampf((crack + body) * 1.2, -1.0, 1.0) * _env(t, d, 0.001))
	# Doppietta del boss: un colpo più profondo e lungo.
	_streams["shotgun"] = _render_filtered(0.55, Vector2(0.8, 0.05), func(t: float, d: float) -> float:
		var blast := _noise() * exp(-t * 14.0)
		var body := sin(TAU * lerpf(150.0, 45.0, t / d) * t) * 0.7 * exp(-t * 8.0)
		return clampf((blast + body) * 1.2, -1.0, 1.0) * _env(t, d, 0.001))
	# Doppietta caricata: due scatti della pompa.
	_streams["reload"] = _render(0.45, func(t: float, _d: float) -> float:
		var local := t if t < 0.22 else t - 0.22
		return (_noise() * 0.6 + sin(TAU * 650.0 * t) * 0.3) * exp(-local * 50.0) * 0.6)
	_streams["enemy_death"] = _render(0.35, func(t: float, d: float) -> float:
		var tone := sin(TAU * lerpf(520.0, 110.0, t / d) * t)
		return (tone * 0.5 + _noise() * 0.2) * _env(t, d, 0.005))
	_streams["stun"] = _render(0.3, func(t: float, _d: float) -> float:
		var local := fmod(t, 0.15)
		var base := 900.0 if t < 0.15 else 700.0
		return sin(TAU * (base - local * 1500.0) * t) * 0.25 * exp(-local * 20.0))
	# Chiamata dei rinforzi via radio: fruscio e voce gracchiante. Suona anche
	# quando parte una sfida (la sirena chiama le ondate).
	_streams["summon"] = _render_filtered(1.0, Vector2(0.7, 0.7), func(t: float, d: float) -> float:
		var voice := signf(sin(TAU * (300.0 + 80.0 * sin(TAU * 5.0 * t)) * t)) * 0.18 * absf(sin(TAU * 3.0 * t))
		return (_noise() * 0.22 + voice) * sin(PI * t / d))
	# Arrivo dei rinforzi: il fumogeno scoppia.
	_streams["summon_pop"] = _render(0.18, func(t: float, d: float) -> float:
		return (_noise() * 0.5 + sin(TAU * 300.0 * t) * 0.2) * _env(t, d, 0.003))
	# Sirena della sfida: un ululato che sale e scende.
	_streams["siren"] = _render(1.6, func(t: float, d: float) -> float:
		var frequency := 600.0 + 350.0 * sin(TAU * 0.9 * t - PI / 2.0)
		return _triangle(frequency * t) * 0.25 * _env(t, d, 0.1))
	# Interfaccia
	_streams["ui_move"] = _render(0.04, func(t: float, d: float) -> float:
		return sin(TAU * 900.0 * t) * 0.2 * _env(t, d, 0.002))
	_streams["ui_confirm"] = _render(0.1, func(t: float, d: float) -> float:
		return _triangle(lerpf(600.0, 950.0, t / d) * t) * 0.3 * _env(t, d, 0.003))
	_build_voices()


## Voci di giocatore e nemici (vedi Voice): versi brevi e secchi a onda
## quadra, come nei vecchi giochi a 8 bit; ognuno li sente con il suo tono.
## notes: le note in Hz, una dopo l'altra (ognuna lunga step secondi, senza
## scivolare dall'una all'altra), duty la larghezza dell'impulso.
func _build_voices() -> void:
	# Colpiti: due note che scendono di colpo.
	_streams["pain_0"] = _render_chip([440.0, 330.0], 0.035, 0.5)
	_streams["pain_1"] = _render_chip([523.0, 392.0], 0.035, 0.25)
	_streams["pain_2"] = _render_chip([392.0, 262.0], 0.04, 0.5)
	_streams["pain_3"] = _render_chip([494.0, 370.0, 330.0], 0.028, 0.25)
	# Abbattuti: un arpeggio che precipita, appena più lungo ma sempre corto.
	_streams["scream_0"] = _render_chip([587.0, 440.0, 330.0, 220.0], 0.04, 0.5)
	_streams["scream_1"] = _render_chip([659.0, 494.0, 370.0, 247.0], 0.04, 0.25)
	_streams["scream_2"] = _render_chip([523.0, 392.0, 262.0, 196.0], 0.045, 0.125)


## Genera un AudioStreamWAV mono a 16 bit campionando generator(t, durata).
func _render(duration: float, generator: Callable) -> AudioStreamWAV:
	return _render_filtered(duration, Vector2.ONE, generator)


## Come _render, con un filtro passa-basso che varia nel tempo da
## lowpass.x a lowpass.y (valori tra 0 e 1: più alti = suono più brillante).
func _render_filtered(duration: float, lowpass: Vector2, generator: Callable) -> AudioStreamWAV:
	var count := int(duration * MIX_RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var filtered := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		var sample: float = generator.call(t, duration)
		filtered += lerpf(lowpass.x, lowpass.y, t / duration) * (sample - filtered)
		data.encode_s16(i * 2, int(clampf(filtered, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream


## Verso a onda quadra: le note una dopo l'altra, a gradini, con un attacco
## istantaneo e uno smorzamento rapido alla fine (niente code lunghe).
func _render_chip(notes: Array, step: float, duty: float) -> AudioStreamWAV:
	var duration := step * notes.size()
	return _render(duration, func(t: float, d: float) -> float:
		var note: float = notes[mini(int(t / step), notes.size() - 1)]
		var pulse := 1.0 if fmod(note * t, 1.0) < duty else -1.0
		return pulse * 0.32 * _env(t, d, 0.002))


## Inviluppo: attacco rapido e poi decadimento fino a zero alla fine.
func _env(t: float, duration: float, attack: float) -> float:
	if attack > 0.0 and t < attack:
		return t / attack
	return clampf(1.0 - (t - attack) / maxf(duration - attack, 0.001), 0.0, 1.0)


func _noise() -> float:
	return randf_range(-1.0, 1.0)


## Onda a dente di sega (il motore della motosega); phase è in cicli.
func _saw(phase: float) -> float:
	return 2.0 * fmod(phase, 1.0) - 1.0


## Onda triangolare; phase è in cicli (frequenza * tempo).
func _triangle(phase: float) -> float:
	return 4.0 * absf(fmod(phase, 1.0) - 0.5) - 1.0
