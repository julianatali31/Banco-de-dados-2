# Exercício - Laços com banco de dados (geração de créditos)

Baseado na tabela `atendimentos`, gerar automaticamente os créditos
(`recebimentos`) das vendas.

## Arquivos

| Arquivo | Conteúdo |
| --- | --- |
| `01_schema.sql` | Tabelas `pessoas`, `atendimentos` e `recebimentos` + criação dos campos `nro_parcelas` e `prazo` |
| `02_funcao_gera_creditos.sql` | Função `gera_creditos(codigo_do_atendimento)` |
| `03_testes.sql` | Massa de teste com o exemplo do enunciado e casos extras |

Execução (PostgreSQL):

```bash
psql -d seu_banco -f 01_schema.sql
psql -d seu_banco -f 02_funcao_gera_creditos.sql
psql -d seu_banco -f 03_testes.sql
```

## Regras implementadas

- **À vista**: `condicao = 'v'` **e** `nro_parcelas = 1` **e** `prazo = 0`.
  Gera uma única parcela, vencendo na data do atendimento e já quitada
  (`pagamento` = data do atendimento).
- **A prazo**: gera `nro_parcelas` registros. A 1ª parcela vence na data do
  atendimento (entrada) e as demais de mês em mês; `pagamento` fica `NULL`.
- O total é dividido igualmente entre as parcelas e a sobra do arredondamento
  vai para a última, de forma que a soma sempre feche com `atendimentos.total`.
- A função é idempotente: apaga os créditos anteriores do atendimento antes de
  gerar os novos, então pode ser reexecutada sem duplicar registros.
- Erros tratados: atendimento inexistente e atendimento com `total <= 0`.

## Resultado do exemplo do enunciado

`atendimentos`

| codigo | data | condicao | total | prazo | nro_parcelas |
| --- | --- | --- | --- | --- | --- |
| 1 | 2026-08-05 | v | 200.00 | 0 | 1 |
| 2 | 2026-08-05 | p | 1000.00 | 2 | 2 |

`recebimentos` (depois de `select gera_creditos(1); select gera_creditos(2);`)

| codigo | atendimento | vencimento | valor | pagamento |
| --- | --- | --- | --- | --- |
| 1 | 1 | 2026-08-05 | 200.00 | 2026-08-05 |
| 1 | 2 | 2026-08-05 | 500.00 | *(null)* |
| 2 | 2 | 2026-09-05 | 500.00 | *(null)* |

## Observações

- O enunciado pede os campos `nro_parcelas` e `prazo`; na imagem de exemplo a
  coluna aparece como `parcelas`. Aqui foi usado o nome do enunciado
  (`nro_parcelas`).
- Na imagem, o atendimento 2 tem `prazo = 2` e as parcelas vencem em 05/08 e
  05/09 (intervalo de 1 mês). Por isso `prazo` é usado aqui como identificador
  de venda à vista/a prazo, e o intervalo entre parcelas é mensal.
