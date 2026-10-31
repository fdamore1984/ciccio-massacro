# Regole di lavoro per Cheech Carnage (Ciccio Massacro)

- **Lingua**: tutto ciò che vede il giocatore è in italiano e in inglese
  (si sceglie in Opzioni; nel browser vale la lingua del sito). I testi del gioco stanno in
  `data/translations.csv` (colonne `it` ed `en`, sempre allineate: ogni
  testo nuovo o cambiato va scritto in tutte e due) e nel codice si usano
  con `tr("CHIAVE")`; mai testi scritti nel codice. Il nome del gioco è
  "Cheech Carnage" in inglese e "Ciccio Massacro" in italiano (chiave
  `GAME_TITLE`). La pagina itch.io resta in inglese (dice che il gioco è in
  italiano e in inglese). Documentazione interna, commenti e commit sono in
  italiano.
- **Ambientazione**: post-apocalittica moderna (città distrutta, edifici
  abbandonati, armi da fuoco e armi improvvisate), niente elementi fantasy o
  medievali nei testi e nella grafica. Gli id interni ereditati (per esempio
  `mana`, `potion`, `totem`, `cave`, `sword_iron`; nei salvataggi vecchi anche
  `stamina`, oggi `battery`) restano per non rompere i
  salvataggi: nel gioco si mostrano col nome nuovo (vedi README).
- **Pagina itch.io sempre aggiornata**: a ogni modifica che cambia ciò che il
  gioco fa o mostra, aggiorna `store/itch/README.md` (descrizione, comandi,
  tag) e rigenera copertina e screenshot con `tools/store_capture.tscn`
  (istruzioni nel README della cartella); con la stessa scena (`-- tutorial`)
  rigenera anche le immagini del tutorial in `assets/tutorial/` (una
  cartella per lingua) e, se cambia una meccanica, aggiorna i testi delle
  sue pagine (`TUTORIAL_*`). itch.io non ha API per la pagina: segnala
  all'utente cosa ricaricare a mano.
- **Contenuti nei dati**: caratteristiche di nemici e simili in `data/`
  (per esempio `data/enemies.json`), separate dal codice.
- **Input**: solo azioni dell'Input Map; tutto deve funzionare con
  controller, con tastiera e mouse e col touch (menù compresi; il touch con
  i controlli a schermo di `scripts/touch_controls.gd`, serve anche per
  giocare dal browser), e i comandi si rimappano da Comandi → Modifica (vedi
  `scripts/keybinds.gd`).
- **Versione web**: il preset "Web" è per il sito ufotizio.com (vedi
  `docs/web.md`): si pubblica sul sito caricando l'export nel bucket R2
  (`tools/carica-giochi.sh` del repo ufotizio-site), mai su itch.io; a ogni
  modifica che tocca la versione web va ricaricato, insieme a
  `store/itch/`, che il sito mostra sotto il gioco. I
  salvataggi nel browser passano da `scripts/cloud.gd`: ogni nuovo file del
  giocatore in `user://` va aggiunto a `Cloud.files()` e caricato con
  `Cloud.push` / `Cloud.remove`.
- **Devlog e copertine su ufotizio.com**: a ogni novità del gioco aggiungi
  una voce in cima a `public/assets/devlog.js` del repo ufotizio-site (in
  italiano e in inglese) e aggiorna le copertine della home
  (`public/assets/ciccio-massacro-it.png` / `-en.png`, copie di
  `store/itch/cover_it.png` / `cover_en.png`); il sito si pubblica a ogni
  push su `main` di ufotizio-site.
- **Asset provvisori**: grafica geometrica disegnata in codice e suoni
  sintetizzati in `scripts/sfx.gd`, finché non arrivano gli asset definitivi.
- **Verifica prima di pubblicare**: import e avvio senza errori né warning
  con Godot 4.4.1, test delle meccaniche toccate, screenshot di controllo.
- **Salvataggi compatibili**: ogni modifica deve lasciare caricabili i
  salvataggi delle versioni precedenti (campi nuovi letti con un valore
  predefinito, niente campi rinominati o tolti senza conversione). I
  salvataggi dei nomi precedenti ("Gobelino", "Ciccio Massacro") vengono
  copiati dalla loro cartella la prima volta (vedi `scripts/save_game.gd`).
- **Merge automatico**: ogni modifica passa da una Pull Request verso `main`;
  quando la CI della PR è verde (export Linux e Windows: si pubblica per Linux / SteamOS e per Windows, anche portatili come l'MSI Claw 8) si fa il
  merge senza chiedere conferma, poi si verifica il caricamento su itch.io
  del build su `main`. Se la CI è rossa, niente merge: si corregge prima.
