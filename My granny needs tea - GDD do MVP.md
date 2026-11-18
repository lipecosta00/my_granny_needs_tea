# My granny needs tea · GDD do MVP

Nov 17, 2026 · @Felipe Costa

## Visão geral

My granny needs tea é um action RPG top-down curto, em pixel art, feito para gamepad e publicado em HTML5 no itch.io. O neto sai para buscar os ingredientes do "chazinho" da vó e, pelo caminho, liberta almas que passam a lutar ao lado dele.

| Item | Definição |
| --- | --- |
| Gênero | Action RPG top-down com companheiros: combate estilo Zelda, coleção de almas com cara de Pokémon |
| Plataforma | Navegador (HTML5) no itch.io. Versão desktop fica pra depois |
| Controle | Gamepad (Xbox e PlayStation). Teclado como alternativa |
| Engine | Godot 4 com GDScript, renderer Compatibility |
| Arte | Kenney Tiny Town, Tiny Dungeon, Tiny Farm e Tiny Battle, mais tiles próprios no mesmo estilo |
| Duração | 30 a 45 minutos (meta) |
| Tom | Aconchegante e sombrio, com humor |
| Referências | Creature Keeper (combate com companheiro), Pokémon de GBA (rotas e mato alto), Zelda (item que abre caminho) |

## Pilares de design

Toda decisão do MVP passa por estes quatro pilares. O que não serve a nenhum deles fica de fora.

1. **Lutar em dupla.** O jogador controla o herói com precisão e a alma age sozinha. A graça está na sinergia: a alma atordoa, o herói finaliza.
2. **Cada alma abre o mundo.** Toda alma conquistada tem uma habilidade que destrava a próxima área. A coleção tem propósito, não é álbum.
3. **Gostoso no controle.** Resposta imediata, rolamento confiável e feedback forte em cada golpe. Se não for bom no gamepad, não entra.
4. **Fofo e sombrio.** Visual de Pokémon de GBA com paleta de outono e noite, e humor no contraste: a vó é claramente uma bruxa e ninguém comenta.

## História e tom

Uma tarefa boba de neto, buscar ingredientes para o chá da vó, vira uma jornada por floresta, pântano e cemitério cheios de almas que não voltaram.

1. **Casa.** O protagonista acorda e, ao sair do quarto, a mãe chama. Ela pede que ele vá até a casa da vó.
2. **Casa da vó.** A casa é "mal-assombrada" e a vó parece uma bruxa. Ela pede três itens para um "chazinho": **cogumelo**, **musgo de árvore morta** e **osso**.
3. **Floresta Escura.** Os três itens estão em áreas diferentes, cada uma mais difícil. Pelo caminho, o jogador liberta almas que viram companheiras.
4. **Volta.** Com os três itens, o jogador retorna e a vó prepara o chá.

**Tom:** humor de contraste. Ninguém estranha a vó bruxa, e o "chazinho" claramente é uma poção. O medo nunca é pesado: o susto vem do clima, não de gore.

**Em aberto:** o final. Proposta: as almas libertadas são de parentes que a vó tentava trazer de volta, e o "chazinho" era o ritual para isso. Dá um fechamento agridoce e uma segunda leitura para o título: a vó nunca precisou do chá, precisava deles.

## Loop principal

&#91;embedded content: loop principal · 5 etapas que se repetem\]

O jogador explora uma rota, luta em dupla, liberta uma alma ou pega um item, e a habilidade nova abre a próxima área, sempre um pouco mais difícil. Uma volta completa leva de 8 a 12 minutos.

## Controles no gamepad

O jogo é pensado para o controle primeiro: tudo cabe nas mãos sem tirar o polegar do analógico esquerdo. O ataque sai na direção em que o herói está virado, como em Zelda, então o analógico direito fica livre no MVP.

| Ação | Xbox | PlayStation | Teclado |
| --- | --- | --- | --- |
| Andar | Analógico esq. / D-pad | Analógico esq. / D-pad | WASD |
| Atacar com a arma do slot I (segurar = carregado) | X | Quadrado | J |
| Atacar com a arma do slot II (segurar = carregado) | Y | Triângulo | K |
| Rolar (com invencibilidade) | B | Círculo | Espaço |
| Interagir, falar, pegar | A | X | E |
| Abrir a roda de armas (segurar) | LB | L1 | Q |
| Habilidade da alma selecionada | RB | R1 | R |
| Trocar alma selecionada | D-pad ← → (com a roda fechada) | D-pad ← → | 1 e 2 |
| Usar poção | D-pad ↑ | D-pad ↑ | F |
| Pausa | Start / Menu | Options | Esc |

**Roda de armas.** Segurar LB desacelera o tempo para 20%, abre a roda em volta do herói e o analógico esquerdo escolhe a arma. Com a arma destacada, apertar X ou Y equipa no slot correspondente. Soltar LB fecha a roda e o tempo volta ao normal.

**Regras de conforto**

- Zona morta do analógico em 0,2 e movimento em 8 direções, com o sprite virando nas 4 direções mais próximas.
- Buffer de entrada de 0,15 s para ataque e rolamento, então o comando apertado no fim de uma animação não se perde.
- Vibração curta ao levar dano e ao acertar um golpe carregado, com opção de desligar.
- Os ícones de botão na tela seguem o controle conectado (Xbox ou PlayStation), com fallback para Xbox.

## Combate

O herói luta com duas armas equipadas e as almas atacam sozinhas, herdando o combate automático do Unreturned Souls, jogo anterior do mesmo autor. Os números abaixo são valores iniciais de ajuste, todos expostos com `@export` para calibrar jogando.

**Herói**

- Vida: 6 corações, e cada golpe comum tira meio coração.
- Rolamento: 0,35 s de duração, com invencibilidade nos primeiros 0,25 s e recarga de 0,4 s. Sem barra de stamina no MVP.
- Ataque carregado: segurar o botão por 0,6 s. O herói anda devagar enquanto carrega e um brilho avisa quando está pronto.
- Ao levar dano: recuo, 0,8 s de invencibilidade com o sprite piscando.

**Armas do MVP**

| Arma | Sprite | Ataque normal | Ataque carregado | Papel |
| --- | --- | --- | --- | --- |
| Espada | Tiny Dungeon (8,8) | Arco curto e rápido, 1 de dano | Investida curta, 3 de dano | Arma inicial, equilibrada |
| Machado | Tiny Dungeon (11,9) | Arco largo e lento, 2 de dano | Giro de 360°, 3 de dano | Grupos de inimigos |
| Cajado azul | Tiny Dungeon (10,10) | Projétil em linha, 1 de dano | Três projéteis em leque | Distância, inimigos voadores |

**Sinergia herói + alma**

- O inimigo **atordoado** por uma alma recebe dano dobrado do herói.
- O inimigo **empurrado** contra uma parede fica atordoado por 1 s.
- O ataque carregado que acerta um inimigo atordoado gera um efeito de impacto maior (pausa de 0,1 s e tremor de tela).

**Feedback de cada golpe:** pausa de impacto de 0,06 s, flash branco no alvo, recuo, número de dano subindo (dígitos do Tiny Battle), partículas e som. Ninguém deve ter dúvida se acertou.

## Almas

O MVP tem duas almas. Cada uma tem um ataque automático, uma habilidade de combate e uma habilidade de exploração que abre a próxima área. As duas seguem o herói ao mesmo tempo, e o RB usa a habilidade da selecionada.

| Alma | Onde aparece | Ataque automático | Habilidade (RB) em combate | Habilidade (RB) na exploração |
| --- | --- | --- | --- | --- |
| Vagalume (amarela) | Bosque dos Cogumelos | Faíscas no inimigo mais próximo, a cada 1,2 s | Clarão: atordoa os inimigos num raio de 3 tiles por 1,5 s. Recarga de 8 s | Luz: ilumina áreas escuras e revela espectros invisíveis |
| Barqueira (azul) | Pântano | Onda curta que empurra o inimigo, a cada 1,5 s | Remo: puxa os inimigos de um cone na frente do herói. Recarga de 8 s | Ponte de névoa: atravessa água nos pontos marcados |

**Comportamento**

- **Seguir:** flutua a 1,5 tile atrás do herói e contorna obstáculos com `NavigationAgent2D`.
- **Atacar:** escolhe o inimigo mais próximo num raio de 5 tiles e nunca se afasta mais de 6 tiles do herói.
- **Voltar:** se ficar presa ou longe demais, some e reaparece ao lado do herói. Alma travada em parede estraga a experiência, então o teleporte é a rede de segurança.
- **Cair:** almas não morrem. Ao perder a "luz" (barra própria), ficam apagadas por 5 s e voltam sozinhas.

**Como se conquista:** a alma aparece presa por inimigos que a guardam. Ao derrotar os guardas, uma cutscene curta mostra a alma se libertando e a habilidade dela é ensinada logo no mapa seguinte (a luz no bosque sombrio do hub, a ponte no canal do próprio pântano).

**Visual:** o fantasma branco do Tiny Dungeon com `modulate` de cor e uma `PointLight2D` suave. Ele balança com um seno em `position.y`, sem precisar de animação desenhada.

## Inimigos e chefe

Sete inimigos comuns e um chefe, todos com sprites do Tiny Dungeon. Cada inimigo ensina uma coisa diferente, e o comportamento é uma máquina de estados simples (patrulhar, perseguir, atacar, recuperar).

| Inimigo | Sprite | Onde | Vida | Comportamento | O que ensina |
| --- | --- | --- | --- | --- | --- |
| Aranha | (2,10) | Hub, Bosque | 2 | Avança em linha reta depois de um aviso | Rolar no tempo certo |
| Morcego | (0,10) | Hub, Bosque, Cemitério | 1 | Voa em zigue-zague e mergulha | Cajado e arma de alcance |
| Rato | (3,10) | Pântano | 1 | Anda em bando de 3 | Machado contra grupos |
| Lesma de lodo | (4,10) | Pântano | 4 | Lenta, deixa rastro que deixa o herói mais devagar | Posicionamento |
| Caranguejo | (2,9) | Pântano | 4 | Bloqueia golpes de frente | Atacar pelos lados, usar o Remo da Barqueira |
| Espectro | (0,9) | Bosque, Cemitério | 3 | Teleporta curto e ataca de perto | Ler o aviso antes do ataque |
| Ciclope | (1,9) | Cemitério | 8 | Investida forte com aviso longo | Atordoar com a Vagalume e punir |

**Variante:** o espectro invisível dos cantos escuros do cemitério só aparece dentro da luz da Vagalume.

**Chefe: o Coveiro** (sprite encapuzado, Tiny Dungeon (3,9), em escala 2x). Vida 40, duas fases, na arena em frente à capela.

1. **Fase 1:** golpes de pá em área com aviso no chão, e a cada 30% de vida perdida ele invoca 2 espectros.
2. **Fase 2 (abaixo de 50%):** apaga as velas e a arena escurece. Só a luz da Vagalume mostra onde ele está, e a Barqueira puxa ele para longe das lápides onde se esconde.

Ao cair, ele larga o **osso**, o terceiro item. A arena fica trancada até o fim da luta.

## Mundo

&#91;embedded content: progressão · 7 mapas, 2 portões de alma\]

Os 7 mapas já existem em JSON com importador para o Godot. A Floresta Escura distribui o jogador para as três áreas, e as setas tracejadas mostram a dependência: a luz da Vagalume abre o pântano e a ponte da Barqueira abre o cemitério. Todo portão é validado por script, então não existe atalho que pule uma alma.

**Estrutura de cada mapa:** estilo Pokémon de GBA, com bordas de árvores, trilhas retas, mato alto onde surgem inimigos, ledges como atalho de volta e uma clareira secreta com baú na floresta. Os mapas atuais serão refeitos nesse formato, começando pela Floresta Escura.

## Interface e HUD

O HUD fica num canto só e some o resto do tempo: a tela é do mapa. Toda tela de menu é navegável só com o D-pad e os botões A e B.

**HUD em jogo (canto superior esquerdo)**

- Corações de vida (Tiny Battle).
- Dois slots de arma com o ícone do botão (X e Y).
- Retrato das almas com a recarga do RB em círculo, e a selecionada destacada.
- Contador de poções.

**Canto superior direito:** os três itens da vó, em cinza até serem coletados.

**Telas**

| Tela | Conteúdo | Observação |
| --- | --- | --- |
| Título | Logo e "Pressione qualquer botão" | Obrigatória no navegador: só depois de um botão o controle aparece e o áudio pode tocar |
| Pausa | Continuar, controles, opções, sair | Opções: volume, vibração, tremor de tela |
| Diálogo | Caixa na parte de baixo, nome de quem fala e retrato | A avança, segurar B acelera |
| Roda de armas | Slots em volta do herói com o tempo desacelerado | Descrita em Controles |
| Game over | "As almas te levam de volta" e reinicia na última entrada de mapa | Sem perda de itens |
| Placa de tutorial | Mini animação da ação com o ícone do botão | Ideia tirada do Creature Keeper |

**Salvamento:** automático ao trocar de mapa (itens, almas, flags e mapa atual).

## Arte e áudio

A arte é toda da linha Tiny da Kenney (CC0), em tiles de 16×16, com o que falta desenhado no mesmo estilo. O clima sombrio vem da iluminação, não de redesenhar a arte.

**Fontes de arte**

| Fonte | Uso |
| --- | --- |
| Tiny Town | Grama, trilhas, árvores, mata, casas, cercas, placas |
| Tiny Dungeon | Paredes e penhascos 3/4, interiores, lápides, personagens, inimigos, armas, poções |
| Tiny Farm | Protagonista, árvores mortas, pinheiros, pedras, animais da vila |
| Tiny Battle | Lago com margem, corações, números de dano, setas e cursor |
| Próprios (estilo Kenney) | Mato alto, ledge, água de pântano, osso, caldeirão, cama, vitória-régia |

**Estilo de mapa:** estrutura de Pokémon de GBA. Bordas de árvores em fileira, trilhas retas com curvas de 90°, lagos retangulares, mato alto como zona de encontro e ledges como atalho.

**Animação por código** (os sprites têm 1 quadro só)

- Andar: quique com tween de escala e posição, e `flip_h` para os lados.
- Atacar: o sprite da arma gira em arco em volta do herói, com rastro de `Line2D`.
- Levar dano: shader de flash branco e recuo.
- Rolar: rotação de 360° com rastro.

**Iluminação:** `CanvasModulate` arroxeado em cada mapa externo, `PointLight2D` no herói e nas almas, e vinheta nas bordas. Interiores ficam mais claros e quentes.

**Áudio**

- Efeitos sonoros com jsfxr, um para cada ação: golpe, acerto, rolamento, dano, alma, item, porta.
- Música: um tema por área (vila, floresta, pântano, cemitério) e um para o chefe. Opção: gerar com o ACE-Step 1.5, que roda localmente e permite uso comercial.
- Arquivos em OGG, que o export web toca sem problema.

## Plataforma e técnica

O alvo é um build web **single-threaded** do Godot 4.3 ou mais novo, publicado no itch.io sem configuração especial de servidor. Duas limitações do navegador moldam o design: o controle só aparece depois de um botão apertado e o áudio só toca depois de uma interação.

**Engine e export**

- Godot 4 com GDScript. C# fica fora porque projetos C# do Godot 4 não exportam para a web ([docs do Godot](https://docs.godotengine.org/de/4.3/_sources/tutorials/export/exporting_for_web.rst.txt)).
- Renderer **Compatibility**: o web roda em WebGL 2.0, porque o Godot ainda não suporta WebGPU, que os outros renderers exigiriam ([docs do Godot](https://docs.godotengine.org/es/4.3/_sources/tutorials/export/exporting_for_web.rst.txt)).
- **Thread Support desligado.** Desde o 4.3, o build single-threaded é o padrão e dispensa os cabeçalhos de SharedArrayBuffer ([progress report do Godot 4.3](https://godotengine.org/article/progress-report-web-export-in-4-3/)). Usar partículas `CPUParticles2D` e evitar física pesada.

**Resolução:** base de 480×270 (30×17 tiles de 16 px), stretch `viewport` com escala inteira, pra o pixel art não borrar. Filtro de textura Nearest no projeto todo.

**Controle no navegador**

- O navegador só detecta o controle depois que um botão dele é apertado ([Godot web progress report 5](https://godotengine.org/article/godot-web-progress-report-5)). Por isso a tela de título pede "Pressione qualquer botão", e o jogo escuta `Input.joy_connection_changed` em vez de checar no `_ready`.
- O mapeamento no web passa pela Gamepad API do navegador, e há relatos de gatilho lido errado (0,5 com o gatilho solto) num build no itch.io ([fórum do Godot](https://forum.godotengine.org/t/trigger-buttons-not-registering-on-html-version-of-game-on-itch-io/64913)). Regra do MVP: **nenhuma ação essencial nos gatilhos**. A poção vai para o D-pad ↑.
- Testar com controle de Xbox e de PlayStation no Chrome e no Firefox antes de cada publicação.

**Áudio:** o navegador só libera áudio depois que o jogador interage com o jogo ([fórum do Godot](https://forum.godotengine.org/t/animationplayers-call-method-track-not-running-on-exported-web-project-until-application-is-foregrounded/120574)). A mesma tela de título resolve.

**Salvamento:** `user://` com `ConfigFile` ou JSON. No navegador ele fica guardado no IndexedDB, então limpar os dados do site apaga o save.

**itch.io**

- Projeto do tipo HTML, com o `index.html` exportado e os arquivos zipados.
- Janela embutida em 960×540 (2x da base) e botão de tela cheia ligado.
- Limites: 500 MB extraídos, 1.000 arquivos e 200 MB por arquivo ([guia de export web](https://www.summerengine.com/de/blog/godot-web-export-guide.md)), muito acima do que o jogo vai usar.
- Começar como rascunho com link secreto para os testes.

## Escopo

O MVP é a história completa do começo ao fim, curta e polida. Tudo que aumenta conteúdo sem provar o combate em dupla fica para depois.

| Dentro do MVP | Fora do MVP (versão 2 ou nunca) |
| --- | --- |
| 7 mapas: casa, vila, casa da vó, floresta, bosque, pântano, cemitério | Mais biomas e mapas gerados a cada partida |
| 2 almas (Vagalume e Barqueira) | Coleção grande de almas, evolução, árvore de habilidades |
| 3 armas (espada, machado, cajado) | Forja, melhorias, raridade de itens |
| 7 inimigos e 1 chefe | Mais chefes, inimigos de elite |
| Poção como único consumível | Culinária, inventário grande, loja |
| Save automático na troca de mapa | Vários slots de save, nuvem |
| Gamepad e teclado no navegador | Toque no celular, desktop, Steam |
| Português e inglês | Outros idiomas |
| Animação por código sobre sprites de 1 quadro | Animações desenhadas quadro a quadro, isométrico ou 3D |

**Critério de pronto:** alguém que nunca viu o jogo termina a história no gamepad, no Chrome e no Firefox, sem travar e sem precisar de explicação fora do jogo.

## Marcos e riscos

Seis marcos em sequência, cada um com um portão: só se passa para o próximo quando o critério é verdade **jogando no gamepad pelo navegador**. O build vai para o itch.io (rascunho) desde o primeiro marco, pra o pipeline web nunca virar surpresa no fim.

1. **Base jogável.** Herói andando com quique, câmera, Floresta Escura importada e export web no itch.io.
   - Portão: anda bem no controle, no Chrome e no Firefox.
2. **Combate do herói.** Espada, rolamento, aranha e todo o feedback de golpe.
   - Portão: derrotar 3 aranhas já é divertido só com quadrados cinzas no fundo.
3. **Primeira alma.** Vagalume seguindo, atacando sozinha, Clarão e Luz.
   - Portão: a dupla é mais divertida que o herói sozinho. Se não for, ajustar antes de seguir.
4. **Conteúdo.** Os 7 mapas, a roda de armas, machado e cajado, Barqueira e os 7 inimigos.
   - Portão: dá pra ir da casa ao cemitério sem travar.
5. **História e chefe.** Cutscenes, diálogos, o Coveiro e o final.
   - Portão: alguém de fora termina o jogo sem ajuda.
6. **Polimento e lançamento.** Áudio, telas, tradução, página do itch.io com GIF e capturas.
   - Portão: o critério de pronto do Escopo.

**Riscos**

| Risco | Sinal de alerta | Plano |
| --- | --- | --- |
| Combate sem graça, como aconteceu no Botijão | Marco 2 sem vontade de jogar de novo | Parar e ajustar números (`@export`) antes de qualquer arte ou conteúdo |
| IA da alma travando em parede | Alma presa ou longe do herói | Teleporte de volta e raio máximo de 6 tiles |
| Controle diferente por navegador | Botão trocado ou gatilho errado | Nada essencial nos gatilhos, testar Xbox e PlayStation no Chrome e no Firefox a cada build |
| Escopo crescer | Vontade de adicionar alma, arma ou mapa | Toda ideia nova vai para a coluna "Fora do MVP" |
| Tempo dividido com o trabalho de clientes | Semanas sem commit | Marcos pequenos e build jogável no itch.io ao fim de cada um |
