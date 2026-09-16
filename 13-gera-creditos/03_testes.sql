-- =============================================================================
-- exercício: laços com banco de dados - geração de créditos (recebimentos)
-- arquivo: 03_testes.sql
-- reproduz o exemplo do enunciado e exercita alguns casos extras.
-- =============================================================================

delete from recebimentos;
delete from atendimentos;
delete from pessoas;

insert into pessoas (codigo, nome) values
    (1, 'funcionário 1'),
    (2, 'cliente 2'),
    (3, 'técnico 3');
select setval(pg_get_serial_sequence('pessoas', 'codigo'), 3);

-- exemplo do enunciado -------------------------------------------------------
insert into atendimentos
    (codigo, data, condicao, total, pessoa_funcionario, pessoa_cliente, pessoa_tecnico, prazo, nro_parcelas)
values
    (1, date '2026-08-05', 'v',  200.00, 1, null, null, 0, 1),   -- à vista
    (2, date '2026-08-05', 'p', 1000.00, 1,    2, null, 2, 2);   -- a prazo, 2x

-- casos extras ---------------------------------------------------------------
insert into atendimentos
    (codigo, data, condicao, total, pessoa_funcionario, pessoa_cliente, pessoa_tecnico, prazo, nro_parcelas)
values
    (3, date '2026-08-31', 'p', 100.00, 1, 2, null, 3, 3);       -- divisão inexata + fim de mês
select setval(pg_get_serial_sequence('atendimentos', 'codigo'), 3);

select gera_creditos(1) as parcelas_atendimento_1;
select gera_creditos(2) as parcelas_atendimento_2;
select gera_creditos(3) as parcelas_atendimento_3;

-- re-executar não duplica os créditos
select gera_creditos(2) as reprocessa_atendimento_2;

select codigo, atendimento, vencimento, valor, pagamento
  from recebimentos
 order by atendimento, codigo;

-- conferência: a soma das parcelas tem de fechar com o total do atendimento
select a.codigo,
       a.total,
       sum(r.valor) as soma_parcelas,
       count(*)     as qtd_parcelas
  from atendimentos a
  join recebimentos r on r.atendimento = a.codigo
 group by a.codigo, a.total
 order by a.codigo;
