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

## Rodando

Abra a pasta no Godot 4.3+ e aperte F5.

| Ação | Gamepad (Xbox / PS) | Teclado |
| --- | --- | --- |
| Andar | Analógico esquerdo | WASD / setas |
| Atacar (segurar = carregado) | X / Quadrado | J |
| Rolar | B / Círculo | Espaço |

Linha de comando (o binário do Godot precisa estar no PATH como `godot`):

```bash
godot --headless --path . -s tests/run_tests.gd
```

```bash
godot --headless --path . --export-release "Web" build/web/index.html
```

Antes do primeiro export, crie `build/.gdignore` (vazio) para o Godot não importar a própria saída.
O build web precisa ser servido por HTTP (ex.: `python -m http.server` dentro de `build/web`).

## Estrutura

```
assets/kenney/        Tilesheets Tiny (CC0), atlas 16x16 sem espaçamento
assets/sfx/           Efeitos sintetizados (tools/audio/gen_sfx.py)
src/actors/           TopDownMotor, WalkBounce, herói, inimigos (Enemy + Spider)
src/autoload/         Fx (hitstop, tremor, números, partículas, som, vibração), Settings
src/combat/           HitData, Hitbox, Hurtbox, Health
src/core/             Câmera, sombra, InputBuffer
src/weapons/          WeaponData (.tres por arma)
src/game/             Game: dono do herói, câmera e HUD, carrega mapas
src/ui/               HUD (corações)
src/world/            GameMap (base), tileset e mapas gerados
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
`c` baú · `*` flores · `@` spawn · `S` aranha.

## CI / itch.io

`.github/workflows/ci.yml`: testes → mapas atualizados → export web → artefato `web-build`.
Push na `main` publica no itch.io via butler se existirem o secret `BUTLER_API_KEY` e a
variável `ITCH_TARGET` (`usuario/my-granny-needs-tea:html5`).

## Créditos

Arte: [Kenney](https://kenney.nl) — Tiny Town, Tiny Dungeon, Tiny Farm, Tiny Battle (CC0).
