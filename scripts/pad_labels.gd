class_name PadLabels
## Nomi dei tasti del controller da mostrare al giocatore, letti dall'Input
## Map: il gioco si usa solo col controller (i comandi non si possono
## cambiare). Servono a ControlsPanel, HudActions e ai suggerimenti dei
## pannelli.


## Tasti del controller legati all'azione (pulsanti, levette e grilletti).
static func events(action: String) -> Array[InputEvent]:
	var found: Array[InputEvent] = []
	if InputMap.has_action(action):
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				found.append(event)
	return found


## Tasti di più azioni, senza ripetizioni ("A / B"), o un trattino se non
## ce ne sono.
static func describe(actions: Array) -> String:
	var labels: Array[String] = []
	for action: String in actions:
		for event in events(action):
			var text := label(event)
			if text not in labels:
				labels.append(text)
	return " / ".join(labels) if not labels.is_empty() else TranslationServer.translate("BIND_NONE")


## Primo tasto dell'azione ("" se non ce n'è); short: nome breve, dove c'è
## (le frecce della croce, per la barra delle azioni).
static func primary(action: String, short := false) -> String:
	var found := events(action)
	return label(found[0], short) if not found.is_empty() else ""


## Tasto dell'azione per i suggerimenti dei pannelli ("R3"), o un trattino.
static func hint(action: String) -> String:
	var text := primary(action)
	return text if text != "" else TranslationServer.translate("BIND_NONE")


## Nome di un tasto del controller (short: vedi primary).
static func label(event: InputEvent, short := false) -> String:
	if event is InputEventJoypadButton:
		var index := (event as InputEventJoypadButton).button_index
		if short and TranslationServer.translate("BIND_JOY_SHORT_%d" % index) != "BIND_JOY_SHORT_%d" % index:
			return TranslationServer.translate("BIND_JOY_SHORT_%d" % index)
		return _translated("BIND_JOY_%d" % index, "BIND_JOY", index)
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		var side := "POS" if motion.axis_value >= 0.0 else "NEG"
		return _translated("BIND_AXIS_%d_%s" % [motion.axis, side], "BIND_AXIS", motion.axis)
	return ""


## Testo tradotto della chiave, o quello generico con il numero se la
## chiave non c'è (tasti rari).
static func _translated(key: String, fallback: String, number: int) -> String:
	var text := TranslationServer.translate(key)
	return text if text != key else TranslationServer.translate(fallback) % number
