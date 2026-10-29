class_name SaveGame
## Salvataggi della partita: tre slot, ognuno un file JSON in user://. Il
## menù iniziale fa scegliere lo slot per una nuova partita, mentre
## Continua riprende lo slot salvato più di recente (vedi latest); in
## entrambi i casi lo imposta in slot e Game scrive e legge sempre quello. Il vecchio file unico
## (versioni precedenti) diventa lo slot 1 la prima volta che serve.
##
## La cartella user:// prende il nome dal progetto: con il cambio di nome
## (prima "Gobelino", ora "Ciccio Massacro") i salvataggi vecchi restano
## nella cartella accanto, con il nome di prima. La prima volta, se nella
## cartella nuova non c'è nessun salvataggio, vengono copiati qui.

const SLOTS := 3
const PATH := "user://savegame_%d.json"
## File unico delle versioni precedenti.
const OLD_PATH := "user://savegame.json"
## Nome della cartella dei dati delle versioni con il nome precedente del
## gioco: si trova accanto a quella attuale (vedi _migrate_legacy_dir).
const LEGACY_USER_DIR := "Gobelino"

## Slot della partita in corso (da 1 a SLOTS).
static var slot := 1
## La cartella del nome precedente è già stata controllata.
static var _legacy_checked := false


static func path(index: int) -> String:
	_migrate()
	return PATH % index


static func exists(index := slot) -> bool:
	return FileAccess.file_exists(path(index))


## C'è almeno uno slot salvato.
static func any_exists() -> bool:
	for index in range(1, SLOTS + 1):
		if exists(index):
			return true
	return false


static func write(data: Dictionary) -> bool:
	var file := FileAccess.open(path(slot), FileAccess.WRITE)
	if file == null:
		return false
	data["saved_at"] = int(Time.get_unix_time_from_system())
	# Precisione piena: le posizioni servono identiche (casse aperte, totem).
	file.store_string(JSON.stringify(data, "", false, true))
	return true


static func read(index := slot) -> Dictionary:
	if not exists(index):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path(index)))
	return parsed if parsed is Dictionary else {}


## Momento del salvataggio dello slot (secondi Unix; 0 se lo slot è
## libero). I salvataggi vecchi non hanno l'ora: si usa quella del file.
static func saved_at(index: int, data := {}) -> int:
	if data.is_empty():
		data = read(index)
	if data.is_empty():
		return 0
	return int(data.get("saved_at", FileAccess.get_modified_time(path(index))))


## Slot salvato più di recente (0 se non ce n'è nessuno).
static func latest() -> int:
	var best := 0
	var best_time := -1
	for index in range(1, SLOTS + 1):
		var time := saved_at(index)
		if exists(index) and time > best_time:
			best = index
			best_time = time
	return best


static func delete(index: int) -> void:
	if exists(index):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path(index)))


## Descrizione dello slot per il menù (vuota se lo slot è libero): livello,
## momento del salvataggio (ora locale, "AAAA-MM-GG HH:MM"), tempo di gioco
## in secondi (-1 se il salvataggio è di una versione che non lo contava),
## vita e danno massimi, monete, pozioni, nemici sconfitti e piano del
## sotterraneo (0 in superficie; metro: è nella metropolitana). Nei salvataggi vecchi i campi mancanti si
## ricavano da quelli che ci sono.
static func summary(index: int) -> Dictionary:
	var data := read(index)
	if data.is_empty():
		return {}
	var player: Dictionary = data.get("player", {})
	var stats: Dictionary = player.get("stats", {})
	var level := int(player.get("level", 1))
	var local := saved_at(index, data) + int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var dungeon: Dictionary = data.get("dungeon", {})
	return {
		"level": level, "time": Time.get_datetime_string_from_unix_time(local, true).left(16),
		"play_time": float(data.get("play_time", -1.0)),
		"max_health": int(stats.get("max_health", player.get("base_max_health", Player.START_HEALTH))),
		"damage": int(stats.get("damage", Player.damage_at(level))),
		"gold": int(player.get("gold", 0)),
		"potions": int(stats.get("potions", player.get("potions", 0))),
		"kills": int(data.get("kills", 0)),
		"depth": int(dungeon.get("depth", 0)),
		"metro": str(dungeon.get("kind", "building")) == "metro",
	}


static func _migrate() -> void:
	_migrate_legacy_dir()
	if FileAccess.file_exists(OLD_PATH) and not FileAccess.file_exists(PATH % 1):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(OLD_PATH), ProjectSettings.globalize_path(PATH % 1))


## Copia i salvataggi dalla cartella dei dati del nome precedente, se in
## quella attuale non ce n'è nessuno (i file vecchi restano dove sono).
static func _migrate_legacy_dir() -> void:
	if _legacy_checked:
		return
	_legacy_checked = true
	var current := ProjectSettings.globalize_path("user://")
	var legacy := current.trim_suffix("/").get_base_dir().path_join(LEGACY_USER_DIR)
	if legacy == current.trim_suffix("/") or not DirAccess.dir_exists_absolute(legacy):
		return
	var names: Array[String] = [OLD_PATH.get_file()]
	for index in range(1, SLOTS + 1):
		names.append((PATH % index).get_file())
	for file_name in names:
		if FileAccess.file_exists("user://" + file_name):
			return
	for file_name in names:
		var from := legacy.path_join(file_name)
		if FileAccess.file_exists(from):
			DirAccess.copy_absolute(from, current.path_join(file_name))


static func vector(values: Array) -> Vector2:
	return Vector2(values[0], values[1])


static func array(point: Vector2) -> Array:
	return [point.x, point.y]
