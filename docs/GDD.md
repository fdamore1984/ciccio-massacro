# Cheech Carnage (Ciccio Massacro) — Game Design Document

Documento vivo: da compilare e aggiornare. Le sezioni vuote sono da definire.

## 1. Visione

- **Titolo**: Cheech Carnage (in italiano Ciccio Massacro)
- **Genere**: action RPG post-apocalittico 2D, visuale isometrica, combattimento in tempo reale
- **Piattaforme target**: Windows, Linux, SteamOS (Steam Deck) e Android. Steam per desktop e Deck, Google Play per Android. Per ora il prototipo viene pubblicato per Linux / SteamOS e Windows
- **Pitch in una frase**: Ciccio, un sopravvissuto rosa e rotondo, armato di motosega e bazooka, si fa strada tra le rovine di una città distrutta, diventa più forte e incontra chi gli apre nuove strade.
- **Pubblico**: _da definire_
- **Durata stimata**: _da definire (consigliato 5-10 ore per il primo titolo)_

## 2. Ambientazione e tono

- **Mondo**: una città distrutta da una catastrofe: strade d'asfalto spaccate, grattacieli in rovina, fessure aperte dai terremoti, edifici abbandonati da esplorare piano per piano. Dettagli da definire
- **Epoca e atmosfera**: post-apocalittica moderna
- **Tono**: splatter e ironico (il nome, il protagonista rosa, il sangue abbondante); _da precisare_
- **Riferimenti e ispirazioni**: _da definire_

## 3. Protagonista e personaggi

- **Protagonista**: Ciccio, un sopravvissuto rosa carne e rotondo, che si sporca di sangue a ogni uccisione e a ogni ferita (gli schizzi se ne vanno in fretta) con braccia e gambe sottili, armato di una motosega (corpo a corpo) e di un bazooka (missili a ricerca). Non parla e ride grasso quando abbatte un boss
- **Nemici**: bande di predoni tondi come Ciccio, ognuno con taglia, colore della pelle e accessori (capelli, bandane, berretti, occhiali, maschere) casuali, con armi improvvisate (manganelli, mazze da baseball, tubi, mazze da demolizione) e armi da fuoco (pistole, fucili); il signore della guerra di ogni edificio
- **Personaggi chiave**: personaggi incontrati nella città che introducono nuove quest (per ora solo i commercianti). Elenco _da definire_
- **Fazioni**: _da definire_

## 4. Loop di gioco

Cosa fa il giocatore minuto per minuto, ora per ora:

- **Esplorazione**: girare tra le rovine della città, entrare negli edifici abbandonati e salire i loro piani
- **Combattimento**: in tempo reale. Nel prototipo: combo di colpi di motosega istantanei e sempre più forti (3 colpi all'inizio) chiusa da un colpo potente, barra della Frenesia che si carica colpendo (cala se si smette di attaccare) e, piena, scatena con L1 + R1 un attacco speciale (nemici fermi, sfondo scuro, zoom, Ciccio si teletrasporta da un nemico all'altro colpendo fino a 10 volte), parata tenendo premuto, schivate concatenate con cambio di direzione (parata, schivata e salto annullano subito qualsiasi azione, attaccare interrompe la schivata), salto (anche multiplo) combinabile con la schivata, corsa con scivolata, kit medici e scudo di kevlar che assorbe un colpo (ricarica 30 s), missili del bazooka che inseguono il bersaglio ed esplodono. La parata perfetta stordisce il nemico e potenzia per qualche secondo gli attacchi (più forti e più rapidi). Nemici di nove tipi più il boss, con scatti laterali e attacchi lenti e annunciati; ogni tanto un'orda di zombie debolissimi che corrono verso Ciccio e si spappolano addosso a lui
- **Progressione**: diventare più forte, trovare nuovo equipaggiamento. Nel prototipo: esperienza dai nemici, livelli con una curva che cresce piano; ogni livello aumenta i danni base e fa scegliere un potenziamento
- **Quest**: assegnate da personaggi incontrati lungo il cammino
- **Looting**: sia drop dai nemici sia casse militari e oggetti fissi nel mondo. Tabelle di drop e rarità _da definire_
- **Economia**: i rottami sono la moneta; _da definire_

## 5. Sistemi principali

Priorità di design indicata: il cuore del gioco sono sistema di gioco, inventario e looting. Vanno definiti prima dei contenuti.

| Sistema | Descrizione | Stato |
|---|---|---|
| Movimento | Isometrico, 8 direzioni, col controller. Nel prototipo il movimento segue le direzioni dello schermo, con accelerazione e frenata | prototipo |
| Comandi | Controller, tastiera e mouse (camminata verso il cursore, attacchi verso il cursore), comandi rimappabili da Opzioni (anche lasciati vuoti); touch non supportato. Tutorial a pagine con immagini dal menù iniziale e di pausa | prototipo |
| Sfide | Nel prototipo: sirene d'allarme al centro di piazze piane che avviano una sfida di sopravvivenza di 30 secondi a ondate, tarata sul livello del giocatore | prototipo |
| Mondo | Nel prototipo: città distrutta isometrica 3D generata a caso, tutta in piano, con una griglia ordinata di strade dritte e isolati, grandi palazzi in rovina con le porte degli edifici abbandonati, fessure dei terremoti e pochi ostacoli (rovine, macerie, cumuli di rottami che rallentano) | prototipo |
| Combattimento | Tempo reale: combo di motosega (R1, colpi istantanei), colpo potente (L2), parata (L1), Frenesia con attacco speciale (L1 + R1 a barra piena), schivate concatenate e orientabili (B), salto (A), corsa e scivolata (L3), bazooka con missile a ricerca (X), scudo (Y), kit medici, taniche di carburante ed batterie di ricambio (croce sinistra, destra e giù), torcia elettrica accesa e spenta tenendo premuto L3, inventario (croce su); colpo potente caricabile (consuma carburante; a mezz'aria un tocco fa uno slam che costa carburante e batteria, tenendo premuto con una bomba H si fluttua esposti agli spari), fermo all'impatto, sangue abbondante; nove tipi di nemici, pistoleri e fucilieri compresi, più le orde di zombie | prototipo |
| Progressione | Esperienza, livelli e potenziamenti a scelta | prototipo |
| Inventario | Nel prototipo: oggetti dalle casse (catene per la motosega, giubbotti, scarpe, serbatoi, mirini, manuali, scorte, rottami), un oggetto indossato per tipo. Limite di peso e deposito _da definire_ | prototipo |
| Dialoghi | _da definire_ | da fare |
| Quest | _da definire_ | da fare |
| Salvataggi | Nel prototipo: tre slot, salvataggio automatico e manuale dalla pausa (senza nemici vicini); Continua riprende il salvataggio più recente; i salvataggi si possono eliminare | prototipo |

## 6. Storia

- **Premessa**: _da definire_
- **Struttura** (atti, finali): _da definire_

## 7. Arte e audio

- **Stile grafico**: 2D isometrico (pixel art, disegnato a mano...): _da definire_. Nel prototipo forme geometriche disegnate in codice
- **Risoluzione base**: 1280x720 (impostata nel progetto, modificabile)
- **Musica e suoni**: _da definire_. Nel prototipo effetti sintetizzati in codice (motosega, esplosioni, spari, sirena), da sostituire

## 8. Scope e roadmap

1. **Prototipo**: personaggio che si muove, un nemico, un combattimento
2. **Vertical slice**: un'area completa e giocabile
3. **Contenuti**: aree, quest, nemici, oggetti
4. **Rifinitura**: bilanciamento, UI, audio, bug fixing
5. **Steam**: pagina store, build beta su branch privato, lancio

## 9. Decisioni tecniche

- **Motore**: Godot 4.4, GDScript, renderer Compatibility
- **Isometrico**: terreno a blocchi disegnato in codice, ordinamento per profondità con Y-sort, movimento convertito dagli assi di input agli assi isometrici
- **Input**: controller, tastiera e mouse tramite Input Map, rimappabili; UI utilizzabile con controller, tastiera e mouse
- **Lingue**: italiano e inglese, scelte in Opzioni (all'inizio quella del sistema); traduzioni in `data/translations.csv` (colonne `it` ed `en`)
- **Dati**: contenuti di gioco in `data/` (JSON o risorse), separati dal codice
- **Repository**: ramo unico `main`, CI su GitHub Actions
