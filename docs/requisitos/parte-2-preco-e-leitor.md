# Parte 2 — Preço dos equipamentos, leitor de quantidade e materiais na descrição

Slug sugerido: `preco-e-leitor`

Esta parte é construída em cima da página única da parte 1, que já entrega a página do orçamento, a folha inferior de adicionar, o banco com as colunas de Preço dos equipamentos e o design system em `docs/design-system.html`. Esta parte não muda o schema. Os termos seguem o `GLOSSARY.md`. Componentes novos entram no design system, no Dart e na galeria HTML.

## PDF: versão nova do visualizador

As mudanças desta parte na tabela de Equipamentos e no total do PDF formam uma versão nova do visualizador: a v2 (ADR 0003). A v1, criada na parte 1, não muda. Orçamentos salvos com a v1 continuam aparecendo como foram criados, e rascunhos e orçamentos salvos depois desta parte usam a v2.

## 1. Preço dos equipamentos

É um card abaixo da folha do orçamento, depois de Observações, fora do que o cliente recebe. Tudo nele vale só para este orçamento e mexe apenas em Equipamentos. Serviços sempre saem com o valor.

- **Valor unitário no PDF:**
  - É uma chave.
  - Cada orçamento novo nasce com o padrão definido nas Configurações. Esse padrão vem ligado e é uma opção nova na tela Configurações.
  - Desligada, o PDF tira só a coluna Preço. Qtd, Un e o total de cada linha continuam.
- **Valor dos equipamentos:**
  - É um seletor de três opções exclusivas: Soma dos itens, Total fechado e Aumentar %.
  - Todo orçamento começa em Soma dos itens.
- **Total fechado:**
  - A pessoa digita um valor único, que substitui a soma das linhas.
  - O valor fica fixo mesmo se as linhas mudarem depois.
  - O total fechado trava a chave do unitário em oculto.
  - No PDF, Equipamentos vira uma lista com Qtd, Un e Descrição, sem preço e sem total por linha. A lista fecha com "Valor dos equipamentos" e o valor fechado. A soma real não aparece em lugar nenhum do PDF.
  - Na página, a diferença para a soma das linhas fica à vista, só para a pessoa.
- **Aumentar %:**
  - O seletor anda de 5 em 5 e aceita digitar um valor.
  - O unitário novo é o unitário × (1 + %), arredondado ao centavo. A linha passa a valer qtd × unitário novo, e o subtotal é a soma das linhas.
  - Na página, cada linha mostra o unitário novo e o antigo riscado. O subtotal aparece como antes → depois.
  - O PDF mostra só os preços novos. Nada nele indica que houve aumento.
  - O catálogo não muda.
- **Na página, a pessoa vê todos os preços:**
  - O que não vai sair no PDF aparece apagado, com o ícone de olho cortado.
  - No total fechado, os valores das linhas ficam cinza, só como referência.
- **Totais:** o total do topo da página e o total do PDF sempre batem, já com o total fechado ou o aumento aplicados.
- **Salvar:** o orçamento salvo registra o total já com o Preço dos equipamentos aplicado.

## 2. Leitor de quantidade (só no campo Nome de Equipamentos)

- A pessoa digita como fazia na descrição do serviço: `qtd [unidade] nome`. Por exemplo, `6 placa de advertencia` ou `200 m fio inox`.
- **Quantidade:**
  - Só o número no começo do texto vira quantidade.
  - Tem que ser um inteiro de 1 a 9999.
  - O número vira um chip azul, "Qtd N separada do nome", com o botão "Desfazer".
  - "Desfazer" devolve o número para o nome, para casos como "3 em 1" ou "kit 2 portas".
- **Unidade:**
  - É reconhecida só quando a palavra logo depois do número é a abreviação de uma unidade cadastrada.
  - Se a pessoa escolher um item do catálogo, vale a unidade do item, não a digitada.
- **Busca:** o resto do texto é o que busca no catálogo.
- **Em Serviços:** o leitor não age no campo Nome.

## 3. Materiais na descrição do serviço

- **Detecção:**
  - Na folha de serviço, o mesmo leitor percorre a descrição e marca cada linha que começa com número.
  - Quando acha alguma, a folha avisa quantas linhas parecem materiais e oferece dois botões: "Levar para Equipamentos" e "Manter".
- **"Levar para Equipamentos":**
  - Cada linha detectada vira uma linha de Equipamentos.
  - **Com par no catálogo:** a linha só se liga a um item do catálogo quando o nome normalizado (sem acento, sem diferença de maiúsculas, espaços aparados) é exatamente igual ao do item.
  - **Sem par exato:**
    - A linha vira um Item novo no catálogo com preço R$ 0,00.
    - Fica marcada "sem preço" na página até a pessoa preencher o preço.
    - O PDF não é bloqueado por isso.
  - **Equipamento repetido:** se o equipamento já está no orçamento, a quantidade soma na linha existente, como na parte 1.
  - **Descrição:** as linhas levadas saem da descrição do serviço.
- **"Manter":** o texto fica como está.

## Fora desta parte

- Total fechado ou percentual para serviços.
- Quantidade com decimais.
- Reconhecer unidade que não está cadastrada.
- Ler número no meio do nome.
- Mesclar itens do catálogo.
- Kits de serviço com materiais.
- Número DLF.
