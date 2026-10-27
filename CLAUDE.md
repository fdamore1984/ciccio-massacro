# Regole di lavoro per Ciccio Massacro

- **Lingua**: tutto ciò che vede il giocatore è in italiano. I testi del
  gioco stanno in `data/translations.csv` (colonna `it`; la colonna `en`
  resta per un'eventuale versione inglese, da tenere allineata) e nel codice
  si usano con `tr("CHIAVE")`; mai testi scritti nel codice. La pagina
  itch.io resta in inglese (dice che il gioco è in italiano). Documentazione
  interna, commenti e commit sono in italiano.
- **Ambientazione**: post-apocalittica moderna (città distrutta, edifici
  abbandonati, armi da fuoco e armi improvvisate), niente elementi fantasy o
  medievali nei testi e nella grafica. Gli id interni ereditati (per esempio
  `mana`, `potion`, `totem`, `cave`, `sword_iron`; nei salvataggi vecchi anche
  `stamina`, oggi `battery`) restano per non rompere i
  salvataggi: nel gioco si mostrano col nome nuovo (vedi README).
- **Pagina itch.io sempre aggiornata**: a ogni modifica che cambia ciò che il
  gioco fa o mostra, aggiorna `store/itch/README.md` (descrizione, comandi,
  tag) e rigenera copertina e screenshot con `tools/store_capture.tscn`
  (istruzioni nel README della cartella). itch.io non ha API per la pagina:
  segnala all'utente cosa ricaricare a mano.
- **Contenuti nei dati**: caratteristiche di nemici e simili in `data/`
  (per esempio `data/enemies.json`), separate dal codice.
- **Input**: solo controller, solo azioni dell'Input Map; tastiera, mouse
  e touch non sono supportati e i comandi non si
  possono rimappare. Menù compresi, tutto deve funzionare col controller.
- **Asset provvisori**: grafica geometrica disegnata in codice e suoni
  sintetizzati in `scripts/sfx.gd`, finché non arrivano gli asset definitivi.
- **Verifica prima di pubblicare**: import e avvio senza errori né warning
  con Godot 4.4.1, test delle meccaniche toccate, screenshot di controllo.
- **Salvataggi compatibili**: ogni modifica deve lasciare caricabili i
  salvataggi delle versioni precedenti (campi nuovi letti con un valore
  predefinito, niente campi rinominati o tolti senza conversione). I
  salvataggi del vecchio nome ("Gobelino") vengono copiati dalla loro
  cartella la prima volta (vedi `scripts/save_game.gd`).
- **Merge automatico**: ogni modifica passa da una Pull Request verso `main`;
  quando la CI della PR è verde (export Linux e Windows: si pubblica per Linux / SteamOS e per Windows, anche portatili come l'MSI Claw 8) si fa il
  merge senza chiedere conferma, poi si verifica il caricamento su itch.io
  del build su `main`. Se la CI è rossa, niente merge: si corregge prima.
