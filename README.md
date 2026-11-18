# My granny needs tea

Action RPG top-down em pixel art para gamepad, publicado em HTML5 no itch.io.
Design completo em [`My granny needs tea - GDD do MVP.md`](My%20granny%20needs%20tea%20-%20GDD%20do%20MVP.md).

**Engine:** Godot 4.3+ · GDScript · renderer Compatibility · export Web single-threaded.

## Estado: Marco 1 — Base jogável

- [x] Herói andando em 8 direções com quique procedural (sprite de 1 quadro)
- [x] Câmera seguindo com limites do mapa
- [x] Floresta Escura (placeholder em ASCII, ver abaixo)
- [x] Input map completo do GDD (gamepad + teclado)
- [x] Export web single-threaded
- [ ] Portão: testar no gamepad (Xbox e PS) no Chrome e no Firefox
- [ ] Rascunho no itch.io

## Rodando

Abra a pasta no Godot 4.3+ e aperte F5. Teclado: WASD/setas. Gamepad: analógico esquerdo.

Linha de comando (o binário do Godot precisa estar no PATH como `godot`):

```bash
godot --headless --path . -s tests/run_tests.gd
```

```bash
godot --headless --path . --export-release "Web" build/web/index.html
```

O build web precisa ser servido por HTTP (ex.: `python -m http.server` dentro de `build/web`).

## Estrutura

```
assets/kenney/        Tilesheets Tiny (CC0), atlas 16x16 sem espaçamento
src/actors/           TopDownMotor (lógica pura), WalkBounce, herói
src/core/             Câmera, sombra
src/game/             Game: dono do herói e da câmera, carrega mapas
src/world/            GameMap (base), tileset e mapas gerados
tools/                setup_input_map.gd, bake_maps.gd
tests/                Runner headless + testes (CI)
```

### Fontes da verdade geradas por script

| O quê | Edite | Rode |
| --- | --- | --- |
| Input map (`project.godot`) | `tools/setup_input_map.gd` | `godot --headless --path . -s tools/setup_input_map.gd` |
| TileSet + mapas `.tscn` | `src/world/maps/*/*.layout.txt`, `tools/bake_maps.gd` | `godot --headless --path . -s tools/bake_maps.gd` |

O CI falha se o mapa gerado não bater com o layout. Quando o importador JSON dos 7 mapas
entrar, ele substitui o layout ASCII gerando a mesma forma de cena
(`GameMap` > `Ground`, `World/Objects`, `Spawns`).

**Legenda do layout:** `T` floresta · `=` trilha · `~` lago · `"` mato alto · `a` árvore de outono ·
`p` pinheiro · `d` árvore morta · `m` cogumelos · `b` arbusto · `r` pedra · `s` placa ·
`c` baú · `*` flores · `@` spawn.

## CI / itch.io

`.github/workflows/ci.yml`: testes → mapas atualizados → export web → artefato `web-build`.
Push na `main` publica no itch.io via butler se existirem o secret `BUTLER_API_KEY` e a
variável `ITCH_TARGET` (`usuario/my-granny-needs-tea:html5`).

## Créditos

Arte: [Kenney](https://kenney.nl) — Tiny Town, Tiny Dungeon, Tiny Farm, Tiny Battle (CC0).
