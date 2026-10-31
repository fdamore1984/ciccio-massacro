# Pagina itch.io di Cheech Carnage (Ciccio Massacro)

Testi e immagini della pagina itch.io del gioco, allineati all'ultima
versione. Vanno aggiornati a ogni modifica che cambia ciò che il gioco fa o
mostra (vedi `CLAUDE.md`).

itch.io non ha un'API per modificare la pagina: `butler` carica solo le build.
Testi e immagini si inseriscono a mano da **Dashboard → (il gioco) → Edit game**.

Cambio di nome: la pagina è nata come "Gobelino" (https://fdamore1984.itch.io/gobelino),
poi è diventata "Ciccio Massacro"; ora il gioco si chiama "Cheech Carnage" (in
italiano resta "Ciccio Massacro"). Titolo e indirizzo vanno cambiati a mano in
*Edit game* (Title: `Cheech Carnage`; Project URL, per esempio `cheechcarnage`).
Se cambia l'indirizzo, va aggiornata anche la variabile `ITCH_GAME` del
repository GitHub, che la CI usa per caricare le build.

Le immagini si rigenerano con lo strumento di cattura (serve una finestra;
senza schermo si può usare `xvfb-run -a`); l'ultimo comando rigenera le
immagini del tutorial del gioco (`assets/tutorial/`, non vanno sulla pagina):

```bash
godot --path . --resolution 1280x720 res://tools/store_capture.tscn -- screenshots
godot --path . --resolution 1260x1000 res://tools/store_capture.tscn -- cover
godot --path . --resolution 1280x720 res://tools/store_capture.tscn -- tutorial
```

---

## Campi della pagina

| Campo su itch.io | Valore |
|---|---|
| Title | Cheech Carnage |
| Kind of project | Downloadable |
| Release status | Prototype |
| Pricing | No payments (oppure "Donate" se vuoi accettare offerte) |
| Uploads | Caricati dalla CI con butler i canali `linux` e `windows`: in *Edit game → Uploads* spunta la piattaforma Linux sul primo e Windows sul secondo (e rendi di nuovo visibile `windows` se l'avevi nascosto). I vecchi caricamenti `android` vanno eliminati dalla stessa pagina |
| Genre | Action |
| Tags | vedi sotto |
| AI generation disclosure | Sì: codice, testi e grafica provvisoria sono stati prodotti con l'aiuto di un'IA (Claude) |
| Languages | English, Italian |
| Inputs | Keyboard, Mouse, Xbox controller, Playstation controller, Touchscreen |
| Cover image | `cover_en.png` (630×500; `cover_it.png` è la versione italiana) |
| Screenshots | `en_1_combat.png`, `en_16_frenzy.png`, `en_2_parry.png`, `en_5_challenge.png`, `en_6_inventory.png`, `en_9_slam.png`, `en_14_air_charge.png`, `en_15_h_bomb.png`, `en_19_horde.png`, `en_11_cave.png`, `en_13_map.png`, `en_12_dungeon.png`, `en_18_metro.png`, `en_7_merchant.png`, `en_8_shop.png`, `en_3_level_up.png`, `en_4_menu.png`, `en_10_controls.png`, `en_17_options.png` (in inglese, la lingua della pagina; quelle `it_*` sono le stesse in italiano: le vecchie immagini italiane sulla pagina vanno sostituite da queste) |

### Tags

Su itch.io se ne possono mettere al massimo 10:

```
action-rpg, post-apocalyptic, gore, chainsaw, isometric, zombies, horror, controller, procedural-generation, prototype
```

---

## Short description or tagline

```
A pink survivor, a chainsaw, a bazooka and a ruined city full of raiders, zombie hordes and mutants.
```

---

## Description

Da incollare così com'è nel campo *Description*: brevissima, i dettagli li
spiega il tutorial del gioco.

```
Cheech Carnage is a 2D post-apocalyptic action RPG with an isometric view: carve your way with a chainsaw and a bazooka through raiders, zombie hordes and mutants in an endless ruined city, its abandoned buildings and the metro.

Fast, deadly Souls-like combat: combos, parries, dodges, jumps and the Frenzy special attack. Comic-style look, like ufotizio.com: thick ink outlines, big cartoon eyes and a matching interface. Prototype with placeholder graphics and sounds.

Controller, keyboard and mouse or touch. English and Italian. Windows, Linux and Steam Deck.

Play it right in your browser, with your saves on every device: https://ufotizio.com/en/cheech-carnage
```

---

## Sito ufotizio.com

Descrizione brevissima mostrata dal sito sotto il gioco, nella lingua del
sito (non va su itch.io; vedi `public/assets/itch.js` del repo ufotizio-site).

### Italiano

```
Action RPG post-apocalittico: motosega, bazooka e combattimenti senza pietà contro predoni, orde di zombie e mutanti in una città in rovina senza fine.
```

### English

```
Post-apocalyptic action RPG: a chainsaw, a bazooka and merciless fights against raiders, zombie hordes and mutants in an endless ruined city.
```

---

## Download instructions

Campo *Download & install instructions* (sotto la sezione Uploads).

```
HOW TO INSTALL

Play with a controller (the Steam Deck and MSI Claw built-in controls work), with keyboard and mouse or on the touch screen.

Linux / Steam Deck: download the Linux file, extract it and run CheechCarnage.x86_64 (if needed, make it executable first: right click → Properties → Allow executing, or chmod +x CheechCarnage.x86_64). On Steam Deck the game always starts in fullscreen, in Desktop Mode too. Do this in Desktop Mode, then add it to Steam as a non-Steam game (Steam → Games → Add a Non-Steam Game) and always launch it from Steam: this way the built-in controller works as a gamepad, both in Game Mode and in Desktop Mode. If you launch it from the itch.io app in Desktop Mode instead, hold the Menu (Start) button for 1 second to switch the built-in controls to controller mode. If you added an earlier build to Steam when the file was called CiccioMassacro.x86_64, that shortcut keeps working (the old name is kept as a link), but you can point it to CheechCarnage.x86_64 in the game's Properties → Shortcut → Target.

Windows / MSI Claw 8: download the Windows file, extract it and run CheechCarnage.exe (if Windows SmartScreen warns you, click More info → Run anyway). On handheld gaming PCs like the MSI Claw 8 the game starts in fullscreen; play with the built-in controller (XInput mode). You can also add it to Steam as a non-Steam game.

Saves, remapped controls and settings from the earlier "Ciccio Massacro" and "Gobelino" builds are picked up automatically the first time you play.

Tip: with the itch.io app (https://itch.io/app) the game updates automatically to the latest build.
```
