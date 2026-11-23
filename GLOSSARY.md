# Delforte

App de orçamentos para quem instala sistemas de segurança (CFTV, alarme, cerca elétrica, portões). O profissional monta o orçamento no celular e envia ao cliente em PDF.

## Orçamento

**Orçamento**:
Documento com o preço de um trabalho para um cliente: cliente, serviços, equipamentos, condições e observações. Depois de criado, é um documento próprio: mudanças no catálogo ou nos padrões não o alteram.
_Avoid_: Proposta, cotação

**Rascunho**:
Orçamento ainda em montagem. Nasce ao tocar em "Novo Orçamento" e é descartado se for abandonado sem cliente e sem nenhuma linha.
_Avoid_: Draft, orçamento em aberto

**Orçamento salvo**:
Orçamento que ele salvou (ao tocar em Salvar ou Compartilhar no PDF), com o total registrado, e que não muda mais. O PDF dele continua aparecendo como foi criado, mesmo depois que o app muda o desenho do PDF. Editar um orçamento salvo cria um rascunho novo copiado dele; o salvo continua como estava.
_Avoid_: Finalizado, fechado, compartilhado, enviado

**Linha**:
Um serviço ou equipamento dentro de um orçamento. Guarda a própria cópia de nome, descrição, unidade e preço, tirada do catálogo quando entrou, e continua ligada ao item de origem. Nome e unidade são os do item; preço (e, no serviço, a descrição) podem mudar só naquele orçamento.
_Avoid_: Item do orçamento, entrada

**Condições**:
Pagamento, garantia, validade e termos de um orçamento. Vêm preenchidas com os padrões e podem mudar só naquele orçamento.
_Avoid_: Condições comerciais

**Termos**:
Texto das regras gerais do trabalho (o que está incluso, responsabilidades, cobranças extras). É uma das condições do orçamento.
_Avoid_: Termos e condições, contrato

**Observações**:
Texto livre que vale só para aquele orçamento, com o que o cliente precisa saber sobre este trabalho. Começa vazio e sai no fim do PDF.
_Avoid_: Notas, comentários

**Preço dos equipamentos**:
Escolhas de um orçamento sobre como o valor dos equipamentos chega ao cliente: mostrar ou não o preço unitário, somar as linhas, fechar um total ou aumentar os preços em %. Não sai no PDF como seção própria.
_Avoid_: Configurações do orçamento, ajustes, opções do PDF

## Catálogo

**Catálogo**:
Os serviços e equipamentos que o profissional já cadastrou, reaproveitados de um orçamento para outro.
_Avoid_: Produtos, cadastro

**Serviço**:
Mão de obra de um trabalho, com nome, descrição e valor, sem quantidade nem unidade. Os materiais do trabalho não fazem parte do serviço: são equipamentos.
_Avoid_: Kit, pacote

**Item novo**:
Item do catálogo criado de dentro de um orçamento, ao confirmar um nome que o catálogo não sugeriu. Deixa de ser novo quando o orçamento é salvo.
_Avoid_: Item avulso, item rápido

**Equipamento**:
Material ou aparelho cobrado por quantidade, com unidade e preço unitário.
_Avoid_: Material, produto, peça

**Unidade**:
Como a quantidade de um equipamento é medida (un, m, cx, kit).
_Avoid_: Medida

## Configurações

**Configurações**:
Preferências do app inteiro: dados da empresa, padrões e aparência do PDF. Nunca se refere a um orçamento específico.
_Avoid_: Ajustes, preferências

**Padrões**:
Pagamento, garantia, validade e termos que todo orçamento novo recebe ao nascer, definidos nas Configurações.
_Avoid_: Defaults, valores iniciais
