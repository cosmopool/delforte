# Visualizador de PDF versionado: cada mudança no PDF é uma versão nova

O app precisa mostrar um PDF antigo exatamente como ele foi criado, e o PDF é gerado de novo a cada vez que é aberto. Por isso o código que desenha o PDF (o visualizador) tem versões.

## Como funciona
- **Versão guardada:** sempre que o PDF de um orçamento é gerado, o orçamento guarda o número da versão mais recente do visualizador.
- **Abrir o PDF:** é uma entrada única, que só redireciona para a versão guardada naquele orçamento.
- **Rascunho:** é desenhado sempre pela versão mais recente.
- **Orçamento salvo:** fica para sempre com a versão de quando foi salvo (ADR 0002).
- **Editar:** a cópia é um rascunho novo e, por isso, usa a versão mais recente.

## Regra
Qualquer mudança no que o PDF mostra ou em como ele é desenhado cria uma versão nova do visualizador. Isso vale para layout, colunas, rótulos, seções, ordem, fontes e cores fixas. As versões antigas ficam no código sem alteração. Corrigir ou melhorar uma versão que já existe também é feito numa versão nova, nunca na antiga.

## O que não fica congelado
Os dados da empresa, o logo e a cor de destaque vêm das Configurações atuais quando o PDF é aberto. A versão congela o desenho, não esses dados.

## Alternativas descartadas
- **Guardar os bytes do PDF ao salvar:** congela tudo, mas o banco cresce a cada orçamento.
- **Copiar os dados da empresa para cada orçamento:** foi descartado por ora.
- **Não versionar:** uma mudança de layout alteraria orçamentos que o cliente já recebeu, o que contraria a ADR 0002.

## Consequência
O código de PDF cresce a cada mudança, porque as versões antigas nunca são apagadas nem refatoradas. Uma versão que o app não conhece, por exemplo num backup vindo de um app mais novo, mostra uma mensagem de erro e não trava.
