# Pagina itch.io di Ciccio Massacro

Testi e immagini della pagina itch.io del gioco, allineati all'ultima
versione. Vanno aggiornati a ogni modifica che cambia ciò che il gioco fa o
mostra (vedi `CLAUDE.md`).

itch.io non ha un'API per modificare la pagina: `butler` carica solo le build.
Testi e immagini si inseriscono a mano da **Dashboard → (il gioco) → Edit game**.

Cambio di nome: la pagina è nata come "Gobelino" (https://fdamore1984.itch.io/gobelino).
Titolo e indirizzo vanno cambiati a mano in *Edit game* (Title: `Ciccio Massacro`;
Project URL, per esempio `cicciomassacro`). Se cambia l'indirizzo, va aggiornata
anche la variabile `ITCH_GAME` del repository GitHub, che la CI usa per caricare le build.

Le immagini si rigenerano con lo strumento di cattura (serve una finestra;
senza schermo si può usare `xvfb-run -a`):

```bash
godot --path . --resolution 1280x720 res://tools/store_capture.tscn -- screenshots
godot --path . --resolution 1260x1000 res://tools/store_capture.tscn -- cover
```

---

## Campi della pagina

| Campo su itch.io | Valore |
|---|---|
| Title | Ciccio Massacro |
| Kind of project | Downloadable |
| Release status | Prototype |
| Pricing | No payments (oppure "Donate" se vuoi accettare offerte) |
| Uploads | Caricati dalla CI con butler i canali `linux` e `windows`: in *Edit game → Uploads* spunta la piattaforma Linux sul primo e Windows sul secondo (e rendi di nuovo visibile `windows` se l'avevi nascosto). I vecchi caricamenti `android` vanno eliminati dalla stessa pagina |
| Genre | Action |
| Tags | vedi sotto |
| AI generation disclosure | Sì: codice, testi e grafica provvisoria sono stati prodotti con l'aiuto di un'IA (Claude) |
| Languages | Italian |
| Inputs | Xbox controller, Playstation controller (togliere Keyboard, Mouse e Touchscreen) |
| Cover image | `cover_it.png` (630×500) |
| Screenshots | `it_1_combat.png`, `it_2_parry.png`, `it_5_challenge.png`, `it_6_inventory.png`, `it_9_slam.png`, `it_14_air_charge.png`, `it_15_h_bomb.png`, `it_11_cave.png`, `it_13_map.png`, `it_12_dungeon.png`, `it_7_merchant.png`, `it_8_shop.png`, `it_3_level_up.png`, `it_4_menu.png`, `it_10_controls.png` (il gioco è in italiano: le immagini `en_*` e `cover_en.png` vanno sostituite da queste) |

### Tags

Su itch.io se ne possono mettere al massimo 10:

```
action-rpg, post-apocalyptic, gore, chainsaw, isometric, 2d, controller, singleplayer, procedural-generation, prototype
```

---

## Short description or tagline

```
A pink survivor, a chainsaw, a bazooka and a ruined city full of raiders.
```

---

## Description

Da incollare così com'è nel campo *Description* (l'editor accetta il testo
formattato; i titoli si possono rendere in grassetto).

```
Ciccio Massacro is a 2D post-apocalyptic action RPG with an isometric view.

You are Ciccio, a round flesh-pink survivor with a chainsaw in his hands and a bazooka on his back. The city is in ruins, the streets are split by earthquakes and gangs of raiders rule the abandoned buildings: carve your way through them, grow stronger and meet those who will open new paths for you.

⚠️ This is a prototype build: Ciccio and the raiders are placeholder geometric shapes (when they face away from the camera, their weapons and gear disappear behind their bodies) and the sounds and voices are synthesized placeholders. It's here to test the combat. Controller only.

IN THIS PROTOTYPE
- A boundless, randomly generated 3D isometric ruined city, completely flat and laid out on an orderly grid: straight cracked asphalt roads, city blocks with huge ruined buildings and open lots, and abandoned building doors right next to the big buildings. Here and there collapsed brick walls, bent street lights, burned-out cars, concrete rubble and junk piles (junk slows you down)
- Souls-like combat, fast and deadly for both sides: raiders hit hard (two or three mistakes and you're dead) and take a beating before they drop, but they come in small numbers: fights are tense one-on-one duels, not hordes. No more than two raiders attack you at the same time: the others circle around and wait for their turn. Their blows hurt each other too: a swing, a slam or a stray bullet can catch another raider, so make them get in each other's way. Every enemy attack has a clear wind-up, so when you get hit it's on you. Attacks are committed: once a swing starts, yours or theirs, it can't be cancelled
- Blood everywhere: every hit, yours or theirs, sprays gushes of blood that land as jagged splatters on the ground and opens a bleeding wound on the body that fades in a moment; fighters get splattered with blood that wears off quickly. Whoever dies, Ciccio or a raider, leaves a large pool of blood that stays on the ground, and fallen raiders lie in theirs for a while
- Short, snappy 8-bit square-wave blips when someone gets hit or goes down, every fighter with a pitch of their own
- Battery: attacking, dodging, jumping, blocking and running all drain it. Empty it and you can't swing or roll, and a block can break your guard. Spare batteries (D-pad down) recharge it in a hurry. Using a supply takes a moment, and enemies rush in to punish you when you heal or back away
- Chainsaw combat: chain up to 3 attacks in a combo, each hit stronger than the last, and finish it with a power strike for a big bonus (a mixed combo multiplies the power strike's damage). Strikes are deliberate and sweep a wide arc, power strikes an even wider one; hold the attack button to keep swinging
- Parry with your chainsaw across your body: the enemy's strike is cut short and the enemy is pushed back, and bullets bounce off. Time it right before the hit for a perfect parry: the enemy is stunned and your attacks are empowered for a few seconds (double damage, faster swings)
- Dodge with a roll on the ground or an air dash mid-jump, steer it while dodging, and unlock upgrades to chain more dodges in a row. Parrying, dodging or jumping instantly cancels whatever you are doing, even mid-strike; attacking during an air dash turns it into an immediate strike. You can keep moving while attacking and every swing carries you well forward: every strike is different from the last (slash, backhand, overhead chop, thrust) and always hits the same area in front of you
- Jump over enemy attacks (unlock multiple jumps in mid-air) and combine jumps with dodges
- Tap L3 to start or stop running (it stops by itself when you stand still); dodge while running to slide, and attack, dodge, jump or parry out of the slide
- Hold R2 for focus mode: the world dims and loses its colors, with dark edges around the screen, while you, the items to pick up, closed crates, traders, sirens and doors stay in full color with a white aura, so you never miss them
- Medkits, fuel cans and spare batterys: carry up to 10 of each (more with upgrades); the ones you find or buy go straight to your belt (you start with 2 medkits, 1 fuel can and 1 spare battery) and they work right away; Kevlar plates absorb one hit from any direction, recharging in 30 seconds
- Nine kinds of raiders, round like Ciccio, each one born with a random size, skin tone and gear (mohawks, bandanas, caps, sunglasses, gas masks...): quick ones with batons, baseball bat thugs, heavy bruisers with sledgehammers, radio callers that bring in reinforcements (hit them while they call to interrupt them), pipe wielders with long thrusts, nail bat maniacs that strike all around, huge armored juggernauts, pistol gunners and riflemen that shoot from afar. There are only a few of them around at first, a few more as you level up, and they grow tougher with you (and higher up in the buildings): more health, harder hits and, for bruisers, juggernauts and the boss, armor that soaks up part of your damage. You grow too: every level makes your strikes stronger and every few levels adds to your health
- Raiders are solid: you can't walk through them, but bumping into one doesn't hurt. They circle around you with quick sidesteps; watch them wind up (they glow red and pull back their weapon, gunners aim a red laser at you) and lunge leaving a red trail (bright even in the dark): the wind-up is short, so react fast, and beware of chains of strikes. Bat thugs, bruisers, juggernauts and the boss can also leap at you and slam the ground: a red glow on the ground marks where they will land, so get out, dodge or jump. They know how to defend: when they raise their guard your strike bounces off with a flash, your combo breaks and you are pushed back, often into a counterattack. Strike them from the side or from behind, or use ground attacks and missiles to get through
- Walk up to crates, traders, sirens, doors and stairs and an "Interact" prompt appears: press A to use them. Loading screens cover every change of place, so the game never freezes
- No numbers or words pop up over the fighters: when your health runs low the edges of the screen pulse red
- Aerial attacks: attack in mid-air for wide slashes that also reach the enemies below you, and chain them into an air combo
- H-bombs: find them in crates, buy them from traders or loot them from fallen raiders and bosses, and carry up to 3 (one more with each upgrade). With an H-bomb, the power strike in mid-air puts the chainsaw away: Ciccio lifts a huge H-bomb over his head, floats while you hold the button to widen the blast (gunners seize the chance to shoot you down), then plunges and smashes it on the ground. The blast wipes out every raider around and takes a big chunk out of a boss; Ciccio walks away unharmed, just black with soot for a while. No H-bomb, no mid-air power strike
- A power strike during an air dash plunges you down with a wide chainsaw strike. While slamming you pass through enemies, and the impact throws back everyone around (except bosses)
- Hold the power strike to charge it up to double damage (every power strike burns fuel for as long as you hold it: with no fuel left it fires uncharged), and keep holding to chain the next power strikes: if the first one was charged, every power strike chained after it in that combo deals extra damage; every hit you land freezes the action for an instant, throws sparks and knocks the enemy back. Bump into whatever blocks your way (rubble, ruins, crates, walls too high to climb) and it lights up for an instant, bouncing you back a little
- Fire bazooka missiles that seek out and chase the nearest enemy in sight (never one behind a wall or an obstacle) and blow up in a ball of fire, smoke and debris that shakes the screen (they cost fuel: use fuel cans to refill); they crash into ruins, rubble and walls
- Defeated raiders often drop scrap or supplies (medkits, fuel cans or spare batterys), sometimes an H-bomb, rarely an item, and once in a while a rare one
- Day slowly turns to night (a dial next to the minimap shows the sun and the moon crossing the sky): hold L3 to switch your flashlight on or off: its wide, long cone of light follows your gaze across the isometric ground, so you can see at night and inside the buildings. A minimap shows the area around you, enemies as red dots, crates, sirens, traders, building doors, stairs and exits. Press Select for the full map
- Open military crates to find scrap, chainsaw chains, jackets and vests, shoes, fuel tanks, bazooka scopes, manuals, supplies and H-bombs; equip the gear and read the manuals from your inventory, a scrolling grid you can sort by power or value, which compares each piece of gear with the one you are wearing
- Wandering traders are scattered around the city: walk up to their stall and interact to sell the items you don't use and to buy supplies, H-bombs and rare gear you won't find in crates (diamond chain, riot armor, combat boots, military fuel tank, thermal scope, heavy ordnance and survival manuals, survival kits)
- Long rows of ruined skyscrapers and deep earthquake fissures cut across the city: skyscrapers can't be crossed, fissures can swallow you, but a running jump and a couple of air dashes can carry you over the narrow ones. Doors open in the skyscraper walls
- Interact with a building door to explore its dark, abandoned interior floor by floor (regular grids of square rooms, doors and halls): find the stairs in the walls on each floor (2 to 5 floors) and face the Warlord, a tough boss with a spiked helmet and a sledgehammer that grows with your level, in his arena on the last one: he never leaves the arena, calls in reinforcements by radio and, from a distance, pumps his shotgun and fires a spread of buckshot. Beat him for scrap, an H-bomb and special gear you can't find anywhere else. Doors never hide Ciccio: walk into one and he is always drawn in front of it
- The game saves automatically every 5 minutes and whenever you enter a building, waiting until no enemies are nearby (the enemies around, the boss included, are saved too, right where they were and with the health they had left); you can also save from the pause menu at any time, even on the move, as long as no enemies are nearby. Three save slots, side by side: each one shows your level, where you are, health and damage, scrap and medkits, enemies defeated, play time and when it was saved. Pick one when you start a new game (an occupied slot asks for confirmation) and the game is saved there right away; Continue on the title screen picks up your most recent save straight away
- Automatic lock-on, no button needed: you are always locked on the nearest enemy (walls and obstacles never get in the way), and the locked raider glows red. You always face it, your strikes and missiles go its way and the camera keeps it in view; when it falls, the lock moves to the next nearest one
- Tall walls, skyscrapers and ledges that hide your character turn fully transparent around you, showing the ground behind them, so you always see what is happening. When you close a menu with A or B, the button doesn't also make you jump, dodge or open the crate next to you
- Alarm sirens stand in the middle of wide open squares: interact with one to start a 30-second survival challenge with waves of raiders matched to your level, and earn experience and a medkit
- Earn experience to level up: the first ten levels come quickly, then each one takes a little longer. Every level raises your base damage and lets you choose an upgrade: one more combo hit, one more chained power strike, one more chained dodge, one more jump, one more health point, a faster shield recharge (5%), a faster run (5%), more battery (10%), more fuel, stronger missiles, one more supply of each kind carried, one more H-bomb carried, stronger medkits, fuller fuel cans (5%) or one more card to choose from at the next level-ups: three of them (more with that upgrade), picked at random, are offered on cards with icons. Your skill levels are always shown on screen, and the active power-ups are shown as small icons in the bottom-right corner

CONTROLS (controller only)
- Move: left stick
- Chainsaw attack (combo; hold to keep attacking): R1
- Power strike (ends the combo; hold to charge, burns fuel; keep holding to chain; in mid-air, only with an H-bomb: smash it on the ground): L2
- Parry (hold): L1
- Dodge (press again to chain; cancels any action): B
- Jump (cancels any action): A
- Run on/off (dodge while running = slide): tap L3
- Flashlight on/off: hold L3
- Focus (hold: dims the world, highlights you, items, crates and doors): R2
- Bazooka (homing missile): X
- Shield: Y
- Medkit: D-pad left
- Fuel can: D-pad right
- Spare battery: D-pad down
- Interact (crates, traders, sirens, doors, stairs): A
- Inventory: D-pad up (R3 to sort)
- Map: Select
- Pause menu (save, controls, quit to title with confirmation): Start
- Special attacks: power strike right after a combo = mixed combo with bonus damage; charged first power strike = stronger chained power strikes; attack in mid-air = aerial slashes; power strike in mid-air = H-bomb (only if you have one; hold to float and widen the blast); power strike during an air dash = dash strike

Play with a controller (Steam Deck and MSI Claw built-in controls included): keyboard, mouse and touch screens are not supported. The full list of controls is in the main menu. The game is in Italian.

PLATFORMS
Windows (handheld gaming PCs like the MSI Claw 8 included), Linux and SteamOS (Steam Deck). Capped at a steady 60 FPS. On Linux it renders with Vulkan, falling back to OpenGL 3.3 when Vulkan is not available.
```

---

## Download instructions

Campo *Download & install instructions* (sotto la sezione Uploads).

```
HOW TO INSTALL

You need a controller (the Steam Deck and MSI Claw built-in controls work): keyboard and mouse are not supported.

Linux / Steam Deck: download the Linux file, extract it and run CiccioMassacro.x86_64 (if needed, make it executable first: right click → Properties → Allow executing, or chmod +x CiccioMassacro.x86_64). On Steam Deck the game always starts in fullscreen, in Desktop Mode too. Do this in Desktop Mode, then add it to Steam as a non-Steam game (Steam → Games → Add a Non-Steam Game) and always launch it from Steam: this way the built-in controller works as a gamepad, both in Game Mode and in Desktop Mode. If you launch it from the itch.io app in Desktop Mode instead, hold the Menu (Start) button for 1 second to switch the built-in controls to controller mode.

Windows / MSI Claw 8: download the Windows file, extract it and run CiccioMassacro.exe (if Windows SmartScreen warns you, click More info → Run anyway). On handheld gaming PCs like the MSI Claw 8 the game starts in fullscreen; play with the built-in controller (XInput mode). You can also add it to Steam as a non-Steam game.

Saves from the earlier "Gobelino" builds are picked up automatically the first time you play.

Tip: with the itch.io app (https://itch.io/app) the game updates automatically to the latest build.
```
