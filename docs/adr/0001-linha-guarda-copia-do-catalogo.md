# A linha do orçamento guarda cópia do item do catálogo

Cada linha de orçamento guarda a própria cópia de nome, descrição, unidade e preço do item do catálogo, tirada quando o item entrou no orçamento, além do `ref_id` que a liga ao item de origem. Um orçamento enviado ao cliente é um documento: renomear ou repreçar um item no catálogo não pode alterar orçamentos e PDFs já existentes, e a descrição de um serviço precisa poder mudar só naquele orçamento. A duplicação com o catálogo é intencional; não substituir por JOIN.
