extends Node
## Impostazioni del giocatore (autoload "Settings"). Il gioco è in italiano
## e in inglese: i testi stanno in data/translations.csv (colonne "it" ed
## "en"). La lingua si sceglie dal pannello Opzioni e si salva in
## user://settings.json; senza il file (prima partita, versioni precedenti)
## vale quella del sistema: italiano se è l'italiano, inglese per tutte le
## altre. All'avvio applica anche i comandi personalizzati dal giocatore
## (vedi Keybinds).

const PATH := "user://settings.json"
## Lingue del gioco, nell'ordine in cui si scorrono in Opzioni.
const LANGUAGES := ["it", "en"]
const FALLBACK_LANGUAGE := "en"

var language := FALLBACK_LANGUAGE


func _ready() -> void:
	# Prima di leggere le impostazioni: i file del nome precedente del gioco.
	SaveGame.migrate_legacy_dir()
	language = _system_language()
	if FileAccess.file_exists(PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary and str(parsed.get("language", "")) in LANGUAGES:
			language = str(parsed["language"])
	_apply_language()
	Keybinds.load_saved()


## Cambia la lingua (subito, per tutti i testi) e la salva.
func set_language(code: String) -> void:
	if code not in LANGUAGES:
		return
	language = code
	_apply_language()
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"language": language}, "\t"))


## Lingua dei testi e nome del gioco nel titolo della finestra ("Ciccio
## Massacro" in italiano, "Cheech Carnage" in inglese).
func _apply_language() -> void:
	TranslationServer.set_locale(language)
	get_window().title = tr("GAME_TITLE")


## La lingua successiva a quella attuale (per il pulsante delle Opzioni).
func next_language() -> String:
	return LANGUAGES[(LANGUAGES.find(language) + 1) % LANGUAGES.size()]


static func _system_language() -> String:
	var system := OS.get_locale_language()
	return system if system in LANGUAGES else FALLBACK_LANGUAGE
