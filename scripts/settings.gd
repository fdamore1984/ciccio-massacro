extends Node
## Impostazioni del giocatore (autoload "Settings"). Il gioco è in
## italiano: i testi stanno in data/translations.csv (colonna "it"; la
## colonna "en" resta per un'eventuale versione inglese). All'avvio applica
## i comandi personalizzati dal giocatore (vedi Keybinds).

const LANGUAGE := "it"


func _ready() -> void:
	TranslationServer.set_locale(LANGUAGE)
	Keybinds.load_saved()
