# My granny needs tea

Action RPG top-down em pixel art para gamepad, publicado em HTML5 no itch.io.
Design completo em [`My granny needs tea - GDD do MVP.md`](My%20granny%20needs%20tea%20-%20GDD%20do%20MVP.md).

**Engine:** Godot 4.3+ · GDScript · renderer Compatibility · export Web single-threaded.

## Estado

**Marco 1 — Base jogável** (código pronto; falta o portão no gamepad)

- [x] Herói em 8 direções com quique procedural, câmera com limites, Floresta Escura (placeholder)
- [x] Input map do GDD (gamepad + teclado), export web single-threaded
- [ ] Portão: gamepad Xbox e PS no Chrome e no Firefox · rascunho no itch.io

**Marco 2 — Combate do herói** (código pronto; falta o portão)

- [x] Espada: golpe em arco (rastro `Line2D`), segurar 0,6 s = investida de 3 de dano
- [x] Rolamento 0,35 s com 0,25 s de invencibilidade e recarga de 0,4 s
- [x] Buffer de entrada de 0,15 s (por evento: toque mais curto que 1 frame não se perde)
- [x] Aranha: aviso → investida reta; bater em árvore = atordoada (dano dobrado)
- [x] Feedback: hitstop 0,06/0,1 s, flash branco, recuo, número de dano, partículas, som, tremor, vibração
- [x] Corações (meio coração por golpe) e game over com volta à entrada do mapa
- [ ] Portão: derrotar 3 aranhas já é divertido? (ajustar números `@export` jogando)

**Marco 3 — Primeiro pet** (código pronto; falta o portão)

- [x] Vagalume: segue 1,5 tile atrás, atravessa obstáculos (espectral), volta por teleporte além de 8 tiles
- [x] Faíscas teleguiadas no inimigo mais próximo (5 tiles) a cada 1,2 s, sem passar de 6 tiles do herói
- [x] RB contextual: Clarão (atordoa em 3 tiles por 1,5 s, recarga 8 s) ou Luz perto de um portão de escuridão
- [x] Portões de pet ficam abertos para sempre (`GameState`, pronto para o save)
- [x] Barra de luz: o pet apaga por 5 s e volta sozinho · retrato do pet com recarga no HUD
- [ ] Portão: a dupla é mais divertida que o herói sozinho?

**Marco 4 — Conteúdo** (código pronto; falta o portão)

- [x] Roda de armas (LB, tempo a 20%), machado (giro 360°) e cajado (projétil, leque); baús
- [x] Morcego, bando de ratos, lesma de lodo, caranguejo, espectro (e invisível), ciclope
- [x] Barqueira (onda, Remo, ponte de névoa) e Toupeira (mordida, Tremor, túnel)
- [x] 7 mapas: casa, vila, casa da vó, Floresta Escura, Bosque, Pântano, Cemitério
- [x] Saídas com fade, save automático na troca de mapa, diálogos, pedidos da vó e caldeirão
- [x] Teste de progressão do mundo: cada material só com os pets que a vó já criou
- [ ] Portão: dá pra ir da casa ao cemitério sem travar?

## Rodando

Abra a pasta no Godot 4.3+ e aperte F5.

| Ação | Gamepad (Xbox / PS) | Teclado |
| --- | --- | --- |
| Andar | Analógico esquerdo | WASD / setas |
| Atacar (segurar = carregado) | X / Quadrado | J |
| Rolar | B / Círculo | Espaço |
| Habilidade do pet | RB / R1 | R |
| Interagir / falar | A / Cross | E |
| Roda de armas (segurar) | LB / L1 | Q |

Linha de comando (o binário do Godot precisa estar no PATH como `godot`):

```bash
godot --headless --path . -s tests/run_tests.gd
```

```bash
godot --headless --path . --export-release "Web" build/web/index.html
```

Antes do primeiro export, crie `build/.gdignore` (vazio) para o Godot não importar a própria saída.
O build web precisa ser servido por HTTP (ex.: `python -m http.server` dentro de `build/web`).

Builds de debug aceitam `--map=<id>` (e `--pets=all`) para começar direto num mapa:
`casa`, `vila`, `casa_da_vo`, `dark_forest`, `bosque`, `pantano`, `cemiterio`.
Rodar só alguns testes: `TEST_FILTER=world,enemies godot --headless --path . -s tests/run_tests.gd`.

## Estrutura

```
assets/kenney/        Tilesheets Tiny (CC0), atlas 16x16 sem espaçamento
assets/sfx/           Efeitos sintetizados (tools/audio/gen_sfx.py)
src/actors/           TopDownMotor, WalkBounce, herói, inimigos (Enemy + Spider), pets (Pet + Vagalume)
src/autoload/         Fx (hitstop, tremor, números, partículas, som, vibração), Settings, GameState
src/combat/           HitData, Hitbox, Hurtbox, Health
src/core/             Câmera, sombra, InputBuffer
src/weapons/          WeaponData (.tres por arma)
src/game/             Game: dono do herói, câmera e HUD, carrega mapas
src/ui/               HUD (corações)
src/world/            GameMap (base), PetGate, tileset e mapas gerados
tools/                setup_input_map.gd, bake_maps.gd, audio/gen_sfx.py
tests/                Runner headless + testes (CI)
```

### Fontes da verdade geradas por script

| O quê | Edite | Rode |
| --- | --- | --- |
| Input map (`project.godot`) | `tools/setup_input_map.gd` | `godot --headless --path . -s tools/setup_input_map.gd` |
| TileSet + mapas `.tscn` | `src/world/maps/*/*.layout.txt`, `tools/bake_maps.gd` | `godot --headless --path . -s tools/bake_maps.gd` |
| Efeitos sonoros `assets/sfx/*.wav` | `tools/audio/gen_sfx.py` | `python3 tools/audio/gen_sfx.py` |

O CI falha se o mapa gerado não bater com o layout. Quando o importador JSON dos 7 mapas
entrar, ele substitui o layout ASCII gerando a mesma forma de cena
(`GameMap` > `Ground`, `World/Objects`, `Spawns`).

**Legenda do layout:** `T` floresta · `=` trilha · `~` lago · `"` mato alto · `a` árvore de outono ·
`p` pinheiro · `d` árvore morta · `m` cogumelos · `b` arbusto · `r` pedra · `s` placa ·
`*` flores · `@` spawn. Inimigos: `S` aranha · `B` morcego · `R` bando de ratos · `G` lesma ·
`K` caranguejo · `E` espectro · `I` espectro invisível · `C` ciclope. Baús e portões vêm da
lista `MAPS` em `tools/bake_maps.gd`.

## CI / itch.io

`.github/workflows/ci.yml`: testes → mapas atualizados → export web → artefato `web-build`.
Push na `main` publica no itch.io via butler se existirem o secret `BUTLER_API_KEY` e a
variável `ITCH_TARGET` (`usuario/my-granny-needs-tea:html5`).

## Créditos

Arte: [Kenney](https://kenney.nl) — Tiny Town, Tiny Dungeon, Tiny Farm, Tiny Battle (CC0).
Fonte: [Press Start 2P](https://fonts.google.com/specimen/Press+Start+2P) (SIL OFL, `assets/fonts/OFL.txt`).
