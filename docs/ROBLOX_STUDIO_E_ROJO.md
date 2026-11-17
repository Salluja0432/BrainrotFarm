# Roblox Studio e Rojo

## Estado de validação

O código do projeto Roblox está em `roblox/`. A integração preservou os cinco arquivos-fonte/configuração do snapshot original byte a byte. Isso confirma a cópia e a estrutura, **não** a execução do jogo. Na etapa de integração do snapshot, não foram feitos build Rojo, análise Luau ou testes funcionais no Studio.

## Evidência histórica e disponibilidade atual do Rojo

O histórico do projeto registra uma execução anterior de `rojo --version` com resultado `7.7.1` e um build Rojo concluído. Isso é evidência histórica de instalação/uso e de uma compilação anterior; não é um teste repetido nesta revisão.

Na auditoria de 17/11/2026, Rokit 1.2.0 e Rojo 7.7.1 foram encontrados instalados em `%USERPROFILE%\.rokit\bin`, mas esse diretório não estava no `PATH`. Por isso, os comandos `rokit` e `rojo` não eram resolvidos pelo nome no terminal verificado. O arquivo `rokit.toml` está versionado na raiz do repositório e fixa `rojo = "rojo-rbx/rojo@7.7.1"`. Essa declaração define a versão esperada pelo projeto, mas não comprova que ela esteja instalada em outra máquina.

Não foi encontrado log ou metadado que vincule definitivamente o build histórico à versão 7.7.1 nem que demonstre que o arquivo `.rbxlx` aberto no Studio foi gerado por ela. Portanto, o histórico de build é registrado, mas a proveniência da build aberta permanece não confirmada.

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

## Preparar as ferramentas no Windows

O manifesto `rokit.toml` fica na **raiz** do repositório e fixa Rojo 7.7.1. Execute a instalação do Rokit e dos tools a partir dessa raiz, não de `roblox/`.

1. Instale Roblox Studio pelo Roblox Creator Hub.
2. Instale o Rokit no Windows seguindo o README oficial: [rojo-rbx/rokit](https://github.com/rojo-rbx/rokit). O instalador oficial para PowerShell é:

   ```powershell
   Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression
   ```

   Também é possível baixar o executável pela página oficial de releases do Rokit e executar `rokit.exe self-install` em um terminal.
3. Feche e abra novamente o PowerShell. Verifique `rokit --version`. Se o comando não for reconhecido, confira se o diretório de binários do Rokit está no `PATH` do usuário; no ambiente auditado, ele estava em `%USERPROFILE%\.rokit\bin`.
4. No PowerShell, entre na raiz do clone `BrainrotFarm-Control` (ajuste o caminho caso o clone esteja em outro local) e instale as ferramentas declaradas no manifesto:

   ```powershell
   Set-Location "$HOME\Downloads\BrainrotFarm-Control"
   rokit install
   rojo --version
   ```

   O resultado esperado de `rojo --version` é `7.7.1`. Se o repositório já estiver em outro diretório, use esse caminho real. Consulte o [README oficial do Rokit](https://github.com/rojo-rbx/rokit) para os comandos disponíveis.
5. Instale o plugin Rojo 7 no Roblox Studio, compatível com a CLI Rojo 7. O comando `rojo plugin install` pode ser executado depois que a CLI estiver instalada; também é possível instalar o plugin pela página oficial do Rojo.

## Gerar um build local

A geração do build é uma etapa separada da instalação. **Não substitua os backups de transferência**. O artefato gerado abaixo fica em `build/`, diretório ignorado pelo Git.

Execute a partir da raiz do clone:

```powershell
New-Item -ItemType Directory -Force .\build | Out-Null
rojo build .\roblox\default.project.json -o .\build\BrainrotFarm.rbxlx
```

Para live sync, execute `rojo serve .\roblox\default.project.json` a partir da raiz, conecte pelo plugin Rojo no Studio e confira o Explorer antes de sincronizar. O build histórico mencionado acima não substitui a validação reprodutível; live sync e testes funcionais permanecem pendentes.

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
