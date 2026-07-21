# Bataki — Teste Técnico Branch77

Jogo de reação para totem touch vertical: numa grade 3x3, um botão acende e o
jogador precisa tocá-lo o mais rápido possível. Ao acertar, ele apaga e outro
acende na hora — e assim por 30 segundos. No fim, pontuação em destaque +
ranking Top 10 lido de um banco SQL.

Fluxo: **Home → Formulário → Regras (contagem 3-2-1) → Jogo → Pontuação/Ranking → Home**

## Stack

- **Engine:** Godot **4.7.1** (GDScript), renderer **Compatibility (GL)**.
- **Banco de dados:** **SQLite**, via addon
  [`godot-sqlite`](https://github.com/2shady4u/godot-sqlite) (GDExtension,
  release v4.7). Escolhi SQLite por ser embutido: zero servidor pra
  configurar, o banco é um único arquivo — ideal pra um executável standalone
  rodando isolado num totem.
- **Orientação:** retrato (1080×1920 de viewport, com override de janela
  540×960), pensado pra tela cheia vertical.
- **Entrada:** toque **e** mouse (`emulate_touch_from_mouse` ligado).

## O addon SQLite JÁ ESTÁ INCLUÍDO

Diferente do padrão, **os binários do `godot-sqlite` já vêm commitados** em
`addons/godot-sqlite/` (todas as plataformas: Windows, Linux, macOS, Android,
iOS, Web). Isso é de propósito: quem for avaliar não precisa repetir a
instalação manual pela AssetLib. Ao abrir o projeto, o addon já deve estar
ativo em **Project > Project Settings > Plugins**.

Se por algum motivo aparecer desabilitado, basta marcá-lo e reiniciar o
editor. Quando roda certo, o console mostra `Opened database successfully`.

## Como rodar (editor)

1. Abra o **Godot 4.7.1** e importe a pasta deste projeto (`project.godot`).
   Deixe o editor re-importar os assets na primeira abertura.
2. Confirme em **Project > Project Settings > Plugins** que `godot-sqlite`
   está **habilitado** (já deve estar).
3. Rode com **F5**. A cena inicial é `scenes/Home.tscn`.

## Como gerar o executável (Windows)

1. **Project > Export...** → **Add...** → **Windows Desktop**.
   - Se o Godot pedir os *export templates*, baixe em
     **Editor > Manage Export Templates > Download and Install**.
2. Deixe marcado **Embed PCK** (padrão) pra sair um `.exe` único.
3. Clique **Export Project** e salve como `builds/Bataki.exe`.
4. O `.dll` do SQLite (`libgdsqlite.windows.*.dll`) fica dentro de `addons/`
   e é incluído automaticamente pelo export. Teste o `.exe` numa pasta limpa
   antes de entregar.

> O banco é criado sozinho no primeiro fim de partida, em
> `user://bataki.db` → no Windows,
> `%APPDATA%\Godot\app_userdata\Bataki\bataki.db`. Não é preciso rodar nenhum
> script de criação: a tabela `matches` é criada via `CREATE TABLE IF NOT EXISTS`
> na inicialização do `Database` autoload.

## Estrutura do projeto

```
project.godot
icon.svg
addons/
  godot-sqlite/        # addon SQLite (binários de todas as plataformas) — incluído
autoload/              # singletons globais, SEM nenhum código de UI
  GameManager.gd        # máquina de estados + todas as regras (pontuação,
                        # streak, timer de partida, watchdog de ociosidade)
  Database.gd           # TODO o SQL do projeto num arquivo só
  Transition.gd         # fade entre telas
  Audio.gd              # SFX sintetizados proceduralmente (sem assets externos)
ui/
  UIStyle.gd            # toda a estilização (paleta, botões, fontes, glow)
scenes/
  Home.gd/.tscn         # attract screen
  FormScreen.gd/.tscn   # captura de lead (nome obrigatório)
  Rules.gd/.tscn        # regras + contagem 3,2,1
  Game.gd/.tscn         # grade 3x3, HUD, feedback, partículas
  ScoreScreen.gd/.tscn  # pontuação final + ranking (lido do banco)
```

## Modelagem do banco

Tabela única `matches`:

| coluna     | tipo    | notas                                  |
|------------|---------|----------------------------------------|
| id         | INTEGER | PK autoincremento                      |
| name       | TEXT    | obrigatório                            |
| email      | TEXT    | opcional                               |
| company    | TEXT    | opcional                               |
| score      | INTEGER | pontuação final da partida             |
| played_at  | TEXT    | data/hora UTC `YYYY-MM-DD HH:MM:SS`    |

- **Ranking Top 10:** `SELECT ... ORDER BY score DESC, played_at ASC LIMIT 10`.
- **Posição do jogador fora do Top 10:** contada com
  `SELECT COUNT(*) WHERE score > ?` (+1), então a tela destaca "você é #N"
  mesmo quando o jogador não aparece na lista visível.

## Separação lógica × interface

`GameManager`, `Database` e `Audio` não conhecem nenhum nó de UI. Eles só
expõem métodos e emitem sinais (`score_changed`, `combo_triggered`,
`round_time_changed`, `round_finished`). As telas (`Game.gd`, `Home.gd`, ...)
apenas leem/chamam esses singletons e reagem aos sinais — nunca o contrário.
Toda a aparência está concentrada em `ui/UIStyle.gd`.

## Decisões técnicas

- **Visual fiel ao Figma:** paleta `#0A0A0A` de fundo, verdes `#6CE525` /
  `#93FC56`, glow radial no topo, alvos circulares com bloom, HUD em cards,
  cards numerados nas Regras. Cores extraídas dos tokens exatos do Figma
  (incluindo `#4BE000`, `#3DB800`, `#DFFFCB`, `#6CE52524`), todas parametrizadas
  em `UIStyle.gd`.
- **Alvo aceso como orbe:** o botão aceso usa o gradiente radial do Figma
  (`#DFFFCB → #6CE525 → #3DB800`, brilho em 50%/38%) via `GradientTexture2D`
  recortada num círculo por um shader simples — dá o aspecto de esfera
  brilhante do vídeo de referência, não um verde chapado.
- **Backgrounds do Figma:** as telas usam imagens de fundo em
  `assets/bg/` (só o gradiente escuro + glow verde, extraídos das telas do
  Figma) esticadas em tela cheia, com a UI funcional renderizada por cima.
  `bg_standard.png` em todas as telas e `bg_countdown.png` (glow central) na
  contagem regressiva. Se as imagens faltarem, `style_bg()` cai num glow
  gerado por código — a tela nunca fica sem fundo.
- **Alvos sempre circulares:** cada célula da grade é envolvida por um
  `AspectRatioContainer` 1:1, então o botão continua um círculo perfeito
  independentemente de como o `GridContainer` estica a célula.
- **Idle timeout (20s) global:** implementado uma vez só no `GameManager`
  (autoload), que escuta `_input()` em qualquer tela e reseta um `Timer`
  global. Nenhuma tela precisa reimplementar o watchdog, então não há como
  "esquecer" numa tela nova. Ao estourar, volta pra Home e descarta o jogador.
- **Sem estado travado:** a única forma de trocar de tela é via `GameManager`,
  que sempre define um próximo estado válido. Todo caminho tem volta pra Home.
- **Multiplicador de streak:** sobe +1 a cada 5 acertos seguidos (5, 10, 15…)
  e zera ao errar; erro quebra a sequência **sem** tirar pontos. Ajustável em
  `GameManager.STREAK_BONUS_EVERY`.
- **"JOGAR DE NOVO":** por ser totem de evento com fila, o botão vai direto pro
  Formulário (novo lead) em vez de passar pela Home. É uma linha só
  (`GameManager.play_again()`) pra mudar.
- **Áudio sem assets:** os SFX (acerto, combo, erro, clique, contagem, fim de
  partida) são **sintetizados em código** no `Audio.gd` (buffers
  `AudioStreamWAV`). Zero arquivos de som pra licenciar/embarcar — o `.exe`
  fica autocontido. Os tons usam ataque suave (sem "clique" seco), timbres
  senoidais e um filtro passa-baixa pra soar macio; volume global controlado
  em `Audio.MASTER_DB` (padrão -12 dB, discreto).

## Game feel / ajustes vindos do vídeo de referência

- **Transições com fade** entre todas as telas (`Transition.gd`).
- **Pop de escala** no alvo que acende e no acerto.
- **Partículas** (`CPUParticles2D`) explodindo do alvo a cada acerto, com uma
  explosão maior no combo.
- **Flash de tela cheia + texto "COMBO x N!"** quando o multiplicador sobe.
- **Shake de tela** ao errar, além do flash vermelho.
- **HUD do tempo fica vermelho** nos últimos 5 segundos.

## Diferenciais implementados

- Efeitos **sonoros** e de **partículas** no acerto e no combo.
- Estatísticas extras na tela final: **tempo médio de reação** e
  **melhor sequência**.
- Ranking destaca a posição do jogador mesmo fora do Top 10 visível.

## Configurações ajustáveis

Hoje são constantes no topo do `GameManager.gd` (fáceis de editar):
`GAME_DURATION` (30s), `IDLE_TIMEOUT` (20s), `POINTS_PER_HIT` (10),
`STREAK_BONUS_EVERY` (5), `GRID_SIZE` (9). Uma tela de configurações em runtime
ficou como próximo passo.
