-- =============================================================================
-- Exercício: Laços com banco de dados - geração de créditos (recebimentos)
-- Arquivo: 03_testes.sql
-- Reproduz o exemplo do enunciado e exercita alguns casos extras.
-- =============================================================================

DELETE FROM recebimentos;
DELETE FROM atendimentos;
DELETE FROM pessoas;

INSERT INTO pessoas (codigo, nome) VALUES
    (1, 'Funcionário 1'),
    (2, 'Cliente 2'),
    (3, 'Técnico 3');
SELECT setval(pg_get_serial_sequence('pessoas', 'codigo'), 3);

-- Exemplo do enunciado -------------------------------------------------------
INSERT INTO atendimentos
    (codigo, data, condicao, total, pessoa_funcionario, pessoa_cliente, pessoa_tecnico, prazo, nro_parcelas)
VALUES
    (1, DATE '2026-08-05', 'V',  200.00, 1, NULL, NULL, 0, 1),   -- à vista
    (2, DATE '2026-08-05', 'P', 1000.00, 1,    2, NULL, 2, 2);   -- a prazo, 2x

-- Casos extras ---------------------------------------------------------------
INSERT INTO atendimentos
    (codigo, data, condicao, total, pessoa_funcionario, pessoa_cliente, pessoa_tecnico, prazo, nro_parcelas)
VALUES
    (3, DATE '2026-08-31', 'P', 100.00, 1, 2, NULL, 3, 3);       -- divisão inexata + fim de mês
SELECT setval(pg_get_serial_sequence('atendimentos', 'codigo'), 3);

SELECT gera_creditos(1) AS parcelas_atendimento_1;
SELECT gera_creditos(2) AS parcelas_atendimento_2;
SELECT gera_creditos(3) AS parcelas_atendimento_3;

-- Re-executar não duplica os créditos
SELECT gera_creditos(2) AS reprocessa_atendimento_2;

SELECT codigo, atendimento, vencimento, valor, pagamento
  FROM recebimentos
 ORDER BY atendimento, codigo;

-- Conferência: a soma das parcelas tem de fechar com o total do atendimento
SELECT a.codigo,
       a.total,
       SUM(r.valor) AS soma_parcelas,
       COUNT(*)     AS qtd_parcelas
  FROM atendimentos a
  JOIN recebimentos r ON r.atendimento = a.codigo
 GROUP BY a.codigo, a.total
 ORDER BY a.codigo;
