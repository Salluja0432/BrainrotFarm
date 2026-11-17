# Roblox Studio e Rojo

## Estado de validação

O código do projeto Roblox está em `roblox/`. A integração preservou os cinco arquivos-fonte/configuração do snapshot original byte a byte. Isso confirma a cópia e a estrutura, **não** a execução do jogo. Rojo CLI e Roblox Studio não estão disponíveis no ambiente que fez a integração; build, análise Luau e testes funcionais permanecem pendentes.

## Estrutura

```text
roblox/
├── default.project.json
└── src/
    ├── client/Main.client.luau
    ├── server/
    │   ├── DataManager.luau
    │   └── Main.server.luau
    └── shared/Config.luau
```

`default.project.json` mapeia `src/shared` para `ReplicatedStorage.Shared`, `src/server` para `ServerScriptService.Server` e `src/client` para `StarterPlayer.StarterPlayerScripts.Client`. Os caminhos do projeto são relativos ao arquivo Rojo dentro de `roblox/`.

## Preparar as ferramentas

1. Instale Roblox Studio pela página oficial do Roblox Creator Hub.
2. Instale o plugin Rojo compatível com a versão principal do Rojo CLI escolhida.
3. Instale o Rojo CLI por um método oficial (Rokit ou binário oficial) e registre a versão usada. Esta integração não adicionou manifesto nem dependências.
4. Abra um terminal em `BrainrotFarm-Control\roblox`.

Para compilar depois que Rojo estiver disponível, execute `rojo --version` e, com a pasta `build/` do repositório criada, use:

```powershell
rojo build -o ..\build\BrainrotFarm.rbxlx
```

Para live sync, execute `rojo serve` nessa pasta, conecte pelo plugin Rojo no Studio e confira o Explorer antes de sincronizar. A compilação e o live sync **não foram executados nesta integração**.

## Ambiente de desenvolvimento isolado

1. Use uma experiência Roblox de desenvolvimento separada da experiência publicada.
2. Use um DataStore exclusivo para desenvolvimento. O `Config.luau` importado ainda contém `DataStoreName = "BrainrotFarm_v1"`; antes de qualquer teste que use DataStore, prepare uma cópia/branch de teste com um nome exclusivo (por exemplo, `BrainrotFarm_dev`) e confira o valor efetivo no servidor.
3. Habilite Studio Access to API Services somente na experiência de desenvolvimento e somente depois de verificar o nome do DataStore. Não execute testes de persistência contra dados reais de jogadores.
4. Não publique o jogo nem altere configurações de produção como parte de uma validação local.
5. Não configure integração Supabase no cliente. O jogo integrado não chama Supabase; Roblox DataStore permanece fonte de verdade para moedas, inventário e progresso.

## Fluxo de teste

- Primeiro valide estrutura e build Rojo sem conectar ou publicar uma experiência de produção.
- Abra o `.rbxlx` gerado no Studio e revise Output e Explorer.
- Execute os cenários da [Fase 1 em `docs/PLANO_DE_TESTES.md`](PLANO_DE_TESTES.md) usando a experiência e o DataStore de desenvolvimento isolados.
- Registre versão das ferramentas, ambiente, passos, resultado observado e logs. Marque como pendente qualquer cenário não executado.
- Não declare persistência confiável ou Fase 1 aprovada apenas porque os arquivos compilam.

## Mecânicas presentes no snapshot

Compra de ovos, sorteio de criaturas, inventário simples, colocação em slots, renda passiva, venda, guardar, roubo entre bases, proteção temporária e persistência com renda offline. A lista descreve o código, não uma validação funcional.
