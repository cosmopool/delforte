# Parte 1 — Design system e orçamento em página única

Slug sugerido: `pagina-unica`

O orçamento deixa de ser um assistente em etapas (Cliente → Serviços → Equipamentos → Revisão → Envio) e vira uma página só, que se preenche de cima para baixo na mesma ordem em que o PDF sai. Junto vem o design system do app, em Dart e num HTML de galeria. Os termos seguem o `GLOSSARY.md`. As regras de dados seguem `docs/adr/0001-linha-guarda-copia-do-catalogo.md` e `docs/adr/0002-orcamento-salvo-nao-muda.md`.

Esta parte já entrega o app funcionando de ponta a ponta. A parte 2 (Preço dos equipamentos, leitor de quantidade e materiais na descrição) vem depois e não deve precisar mexer no banco.

## Design system

- O nome continua Vigil, com a identidade visual de hoje. Entram três cores novas: `paper` #E8EBF2, `blueM` #5499EE e `pin` #F2542D.
- O código Dart fica em `lib/design_system/`.
- A galeria é o arquivo `docs/design-system.html`, que vai para o repositório. Ele mostra as fundações (cores, tipografia, espaçamento, raios, sombras), cada componente com seus estados e as telas do app. As fontes vêm de `assets/fonts`, sem CDN.
- O HTML manda: se ele e o Dart divergirem, quem está certo é o HTML. Um teste compara os tokens do `:root` do HTML com as constantes Dart e falha quando são diferentes.
- O ponto de partida é o `DelforteApp.jsx` na raiz do repositório. Ele não vai para o repositório e, depois que o design system existir, não é mais citado em lugar nenhum.
- Primeiro entram as fundações e os componentes que já existem. Os componentes novos nascem conforme a página única precisa deles, já com a entrada correspondente na galeria.

## Banco

- O schema é novo, `user_version` 2, sem retrocompatibilidade nem migração, porque ninguém usou o app ainda. Ao abrir um banco com versão menor que 2, o app apaga tudo e recria do zero.
- Backups antigos deixam de ser aceitos na importação.
- O schema já nasce completo, com tudo o que a parte 2 vai usar:
  - por orçamento: as Condições copiadas (pagamento, garantia, validade e termos) e as Observações;
  - por orçamento: o Preço dos equipamentos, ou seja, mostrar ou não o unitário no PDF, o modo (Soma dos itens / Total fechado / Aumentar %), o valor do total fechado e o percentual;
  - nas Configurações: o padrão de "Valor unitário no PDF", ligado.
- A linha do orçamento guarda a própria cópia de nome, descrição, unidade e preço, mais a referência ao item do catálogo (ADR 0001).
- O cliente do orçamento pode ser nulo enquanto ele é rascunho.

## Estados do orçamento

- Só existem dois: Rascunho e Salvo.
- **Rascunho:**
  - Nasce ao tocar em "Novo Orçamento", ainda sem cliente.
  - É descartado se a pessoa sair dele sem cliente e sem nenhuma linha.
  - Ao reabrir, a página abre no topo.
- **PDF de um rascunho:**
  - Tocar em "PDF" num rascunho mostra a prévia sem salvar.
  - Tocar em Salvar ou em Compartilhar na tela do PDF salva o orçamento: o total fica registrado e o orçamento não muda mais (ADR 0002).
- **Tela do PDF:**
  - Tem o botão Compartilhar, que abre a folha de compartilhamento do sistema.
  - Não tem "Copiar link".
- **Lista de orçamentos:**
  - Tocar num orçamento salvo abre o PDF dele.
  - Tocar num rascunho abre a página do orçamento.
- **Menu ⋮ (no card da lista e na tela do PDF):**
  - Num orçamento salvo, tem Editar e Excluir:
    - Editar cria um rascunho novo com a cópia completa de todos os dados, inclusive as Condições, as Observações e o Preço dos equipamentos. A data é a de hoje e não há ligação com o original. O salvo continua como estava.
    - Excluir pede confirmação.
  - Num rascunho, tem só Excluir.

## Página do orçamento

- **Seções, em ordem:** Cliente, Serviços, Equipamentos, Condições, Observações.
- **Topo:**
  - Fica sem barra de etapas e sem botão "Revisar".
  - Mostra o total do orçamento e o botão "PDF".
  - O botão "PDF" só fica ativo quando há cliente e pelo menos uma linha.
- **Cliente:**
  - É escolhido numa folha inferior, com a busca e o cadastro de cliente que existem hoje.
  - A tela Clientes da tela inicial continua como está.
- **Adicionar serviço ou equipamento:**
  - Cada seção tem o seu "+", e os dois abrem a mesma folha inferior. Essa folha também serve para editar uma linha: tocar na linha abre a folha preenchida, com "Remover".
  - **Busca:**
    - A pessoa digita o nome e o catálogo sugere enquanto ela digita.
    - A busca ignora acento e maiúsculas e encontra o texto em qualquer parte do nome.
  - **Nome que o catálogo não sugere** vira um Item novo:
    - A folha avisa antes de confirmar, com o nome exato que vai ser salvo.
    - O botão diz que vai salvar no catálogo: "Adicionar e salvar no catálogo".
    - O nome é salvo como foi digitado, só com a primeira letra maiúscula.
    - A unidade e o preço digitados também vão para o catálogo.
    - A linha mostra a etiqueta "novo no catálogo" até o orçamento ser salvo.
  - **Item que veio do catálogo:**
    - Nome e unidade ficam travados.
    - O preço pode mudar só neste orçamento. No serviço, a descrição também.
    - O catálogo não muda.
  - **Serviço:**
    - Tem nome, descrição e valor.
    - A quantidade é sempre 1 e não há unidade.
    - Escolher um serviço que já está no orçamento abre a linha que já existe, em vez de criar outra.
  - **Equipamento:**
    - Tem quantidade inteira de 1 a 9999, unidade e preço unitário.
    - Escolher um equipamento que já está no orçamento soma a quantidade na linha existente, com limite de 9999.
- **Condições:**
  - São Pagamento, Garantia, Validade e Termos.
  - Ao nascer, o orçamento recebe uma cópia dos Padrões das Configurações.
  - Tocar numa condição muda só este orçamento.
  - O Pagamento é escolhido da lista de formas de pagamento e fica guardado como texto copiado.
  - Termos é texto livre.
  - O rótulo "Termos e Condições" passa a ser "Termos", no app e no PDF.
- **Observações:**
  - É um campo único de texto livre, só deste orçamento.
  - Começa vazio.

## PDF

- O layout continua o de hoje, com estas mudanças:
  - Serviços sai como "Serviço · Valor", com a descrição embaixo do nome e sem as colunas Qtd, Un e Preço.
  - As Condições e os Termos saem da cópia guardada no orçamento, não dos Padrões globais.
  - As Observações saem por último.
- A tabela de Equipamentos fica como hoje: Descrição, Qtd, Un, Preço e Total.

## Catálogo

- O Catálogo mantém as telas próprias de cadastro de serviço e de equipamento.
- O cadastro de serviço perde o campo Unidade.

## O que sai

- O assistente em etapas e tudo o que só ele usa (o enum `QuoteStep`, as páginas de etapa e as rotas do fluxo).

## Fora desta parte

- Preço dos equipamentos: a interface e o efeito no PDF ficam para a parte 2. O schema já os guarda nesta parte.
- O leitor `qtd [unidade] nome` e a detecção de materiais na descrição do serviço (parte 2).
- Número DLF, quantidade com decimais, mesclar itens do catálogo, estado "compartilhado" e versões de orçamento.
