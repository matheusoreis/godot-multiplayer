# Godot Origins

Um projeto multiplayer em Godot com arquitetura cliente/servidor separada, pensado para um jogo de mundo persistente, personagens, mapas e interação online. A estrutura foi desenhada para manter a lógica do jogo e o estado do mundo no servidor, enquanto o cliente fica responsável pela interface, entrada do usuário, renderização e apresentação da experiência.

## Visão geral

O projeto é composto por duas partes principais:

- Client: responsável por conectar ao servidor, renderizar mapas, controlar a HUD, interações do jogador e comunicação com a rede.
- Server: responsável por autenticação, gerenciamento de contas, carga de mapas, NPCs, regras do jogo, sincronização e lógica centralizada.

A ideia central é que o servidor seja a autoridade do estado do jogo. O cliente não decide o destino final da entidade ou a validade de uma ação; ele apenas envia uma intenção para o servidor e recebe o resultado atualizado.

---

## Arquitetura do projeto

### Estrutura principal

```text
godot-origins/
├── client/
│   ├── assets/
│   │   ├── gfx/
│   │   ├── sfx/
│   ├── data/
│   │   ├── maps/
│   │   ├── tilesets/
│   ├── source/
│   │   ├── common/
│   │   ├── gameplay/
│   │   └── gui/
│   │   ├── network/
│   │   ├── scene/
│   ├── main.gd
│   └── project.godot
├── server/
│   ├── source/
│   │   └── common/
│   │   ├── database/
│   │   ├── gameplay/
│   │   ├── network/
│   ├── main.gd
│   └── project.godot
└── README.md
```

### Cliente

No cliente, a arquitetura é orientada por cenas, eventos de rede e apresentação do mundo.

- `Main` inicializa a rede do cliente e carrega a cena inicial.
- `Scene` é a base para as telas e cenas do jogo, com suporte a interfaces e acesso à rede.
- `Event` classes expõem as operações remotas para o servidor, como resultado das operações solicitadas ao servidor.

Em resumo, o cliente funciona como uma camada visual e interativa sobre o mundo que o servidor decide.

### Servidor

No servidor, a arquitetura é focada em regras, estado e persistência.

- `Main` inicia o banco, cria a rede, carrega mapas e NPCs e inicia o loop do servidor.
- `Database` inicializa o banco local.
- `Repository` classes acessam persistência e dados como contas, mapas e NPCs.
- `Manager` classes encapsulam a lógica de negócios e validam ações do jogador.
- `Event` classes expõem as operações remotas para o cliente, como login, seleção de personagem, movimentação e dados do mapa.
- `Loop` executa tarefas recorrentes.

Essa abordagem separa responsabilidade por camada:

- banco -> persistência
- repository -> acesso aos dados
- manager -> regras do jogo
- event -> interface de rede
- main -> orquestração

---

## Como a rede funciona

A camada de rede foi construída com uma base comum chamada `Network`, que serve como camada de abstração para o cliente e servidor. A ideia é registrar funções que podem ser chamadas remotamente e serializar o payload em um pacote simples, evitando enviar e receber pacotes em bytes ou json.

### Classe base

A base `Network` define:

- registro de funções remotas
- validação de parâmetros
- hash de identificação do método
- serialização e desserialização de pacotes

Os métodos são registrados com `register([...])` e o id do método é calculado com base no nome do método dentro do escopo `Network`.

```gdscript
var fn_id: int = ('%s.%s' % [SCOPE, fn_name]).hash()
```

Isso cria uma chave estável para cada função remota, permitindo que o pacote identifique qual callback deve ser executado no destino.

### Formato do pacote

O pacote envia um array com duas posições:

```gdscript
[fn_id, args]
```

Onde:

- `fn_id`: hash da função remota a ser chamada
- `args`: lista de argumentos para a função

Exemplo conceitual:

```gdscript
_network.exec(target, &"move_character", [Vector2i(1, 0)])
```

Isso vira algo como:

```gdscript
[hash("Network.move_character"), [Vector2i(1, 0)]]
```

Em seguida o pacote é serializado com `var_to_bytes()` e enviado pela camada `Framed`.

### Recebimento de pacotes

No lado receptor, a rede faz o processo inverso:

1. recebe bytes via `Framed`
2. converte com `bytes_to_var()`
3. valida se o pacote é um `Array` e se a estrutura está correta
4. busca o `fn_id` no dicionário de funções registradas
5. valida os argumentos esperados
6. chama a função via `callv()`

A validação é importante porque evita que o cliente ou atacante envie dados com formato incorreto ou incompatível.

```gdscript
if _validate_args(PACKET_TY, packet) != OK:
    return

var entry: Variant = _lookup.get(packet[0])
if entry == null:
    return

if _validate_args(entry[1], packet[1]) == OK:
    entry[0].callv(packet[1])
```

### Cliente

No cliente, a classe `Network.Client`:

- cria um `FramedClient`
- conecta sinais de `connected`, `disconnected` e `packet_received`
- envia mensagens para o servidor com `exec()`
- recebe respostas e dispara a função registrada localmente

A rotina de polling é essencial:

```gdscript
func poll() -> void:
    if _framed == null:
        return

    _framed.poll()
    if _client:
        _client.poll()
```

Isso mantém a comunicação viva e processa mensagens recebidas em tempo real.

### Servidor

No servidor, a classe `Network.Server`:

- cria um `FramedServer`
- monitora clientes conectados e desconectados
- mantém uma lista de peers ativos
- identifica qual cliente enviou a mensagem via `sender_id()`
- envia mensagens para um cliente específico ou para múltiplos peers

O servidor também usa `exec(target, fn_path, args)` para responder ao cliente ou difundir eventos para outros peers.

Exemplo de fluxo:

- cliente envia `move_character`
- servidor valida se o personagem pode se mover
- se válido, atualiza estado do personagem
- servidor envia para os outros clientes do mapa a atualização de movimento

Isso é central para a sincronização de mundo.

---

## Eventos e API de rede

A rede não expõe funções soltas e arbitrárias em qualquer lugar. Em vez disso, o projeto organiza a API do jogo em eventos por domínio.

### Exemplos no cliente

- `AccountEvent`: login, cadastro, personagem, seleção e listagem
- `MapEvent`: dados do mapa, personagens em cena, movimentação e warps
- `ChatEvent`: mensagens e comunicação entre jogadores
- `NpcEvent`: interação com NPCs

### Exemplos no servidor

- `AccountEvent`: autenticação, criação e seleção de conta/personagem
- `MapEvent`: movimentação, entrada e saída de mapa, envio de dados e sincronização
- `ChatEvent`: envio de mensagens
- `NpcEvent`: comportamento e interação dos NPCs

Cada evento registra as funções que ele responde. Isso deixa a comunicação bem organizada e facilita manutenção.

Exemplo servidor:

```gdscript
func register() -> Error:
    return _network.register([
        map_data,
        enter_map,
        move_character
    ])
```

Exemplo cliente:

```gdscript
func register() -> Error:
    return _network.register([
        map_data,
        character_data,
        character_to_characters,
        move_character,
        correct_movement,
        character_left,
        warp_map
    ])
```

Essa padronização torna a rede previsível e fácil de evoluir.

---

## Fluxo de um ciclo de jogo

Um exemplo típico de fluxo no projeto:

1. O cliente inicia a conexão com o servidor.
2. O usuário faz login ou cria uma conta.
3. O servidor valida as credenciais e responde com confirmação.
4. O cliente seleciona um personagem.
5. O servidor prepara os dados do mapa e envia as informações iniciais.
6. O cliente instância o mapa, os personagens e os NPCs.
7. O jogador se movimenta.
8. O cliente envia `move_character` para o servidor.
9. O servidor valida colisões, limites do mapa e regras.
10. O servidor notifica os demais clientes relevantes sobre a mudança.

Esse tipo de fluxo garante que o mundo seja consistente para todos os jogadores conectados.

---

## Banco de dados e persistência

O servidor usa banco de dados para persistir dados relacionados a contas e personagens.

- `AccountRepository`: dados de login e conta
- `MapRepository`: dados de mapas
- `NpcRepository`: dados de NPCs

Além disso, o servidor tem gerenciadores que transformam dados em operações de gameplay:

- `AccountManager`
- `MapManager`
- `NpcManager`

Isso separa dados brutos de regras do jogo.

---

## Loop e gameplay

O servidor também gera eventos periódicos, como o tick de NPCs.

```gdscript
_loop.add(&"npc_tick", Constants.NPC_STEP_INTERVAL, func(delta: float) -> void:
    _npc_manager.tick(delta)
)
```

Isso permite que a lógica dos NPCs seja processada de forma independente da rede, mantendo uma atualização regular no mundo do servidor.

---

## Principais pontos da arquitetura

A arquitetura escolhida tem alguns aspectos fortes:

- Separação clara entre cliente e servidor
- Centralização da lógica de jogo no servidor
- Comunicação padronizada por eventos e funções remotas
- Mesmo payload formatado em uma estrutura simples
- Validação forte de tipos e argumentos
- Organização por domínio: conta, mapa, NPC, chat, ação
- Persistência desacoplada da lógica de rede

Esse desenho facilita manutenção, expansão e implementação de novas features sem misturar responsabilidades.

---

## Como rodar o projeto

1. Abra o projeto Godot com a pasta raiz do repositório.
2. Inicie a build do servidor e do cliente separadamente.
3. O cliente deve conectar ao endpoint configurado em `Constants.ENDPOINT`.
4. O servidor deve estar ativo antes de iniciar a sessão do cliente.

O projeto usa valores de configuração centralizados em `Constants`, o que facilita ajustar IP, portas, versões e intervalos de jogo.

---

## Observações finais

Este projeto segue uma abordagem bem comum em jogos multiplayer: o cliente é uma interface e o servidor é a fonte de verdade. A camada de rede foi pensada para ser simples, eficiente e extensível, com um protocolo mínimo e organizado por eventos.

A combinação de `Framed` e `Aslet` cria uma estrutura que mantém o código modular, facilita a compreensão e dá uma base sólida para continuar evoluindo o jogo.

Agradecimento especiais ao https://github.com/carabalonepaulo/ pelo ótimo trabalho no `Framed` que possibilitou um Network de forma estável e veloz, e `Aslet` por ter possíbilitado SQLite de forma async na godot, sem você esse projeto não estaria no estado atual!