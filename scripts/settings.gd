extends Node
## Impostazioni del giocatore (autoload "Settings"). Il gioco è in
## italiano: i testi stanno in data/translations.csv (colonna "it"; la
## colonna "en" resta per un'eventuale versione inglese).

const LANGUAGE := "it"


func _ready() -> void:
	TranslationServer.set_locale(LANGUAGE)
