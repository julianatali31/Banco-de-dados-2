-- =============================================================================
-- exercício: laços com banco de dados - geração de créditos (recebimentos)
-- arquivo: 02_funcao_gera_creditos.sql
--
-- gera_creditos(codigo do atendimento) percorre, com um laço, o número de
-- parcelas do atendimento e grava um registro em recebimentos para cada uma.
--
-- regras adotadas:
--   * é à vista quando condicao = 'v' e nro_parcelas = 1 e prazo = 0.
--     nesse caso gera uma única parcela já quitada (pagamento = data).
--   * a prazo, a 1a parcela vence na data do atendimento (entrada) e as
--     demais de mês em mês; o pagamento fica em aberto (null).
--   * o valor é dividido igualmente; a diferença de arredondamento vai
--     para a última parcela, de modo que a soma feche com o total.
--   * a função é idempotente: apaga os créditos anteriores do atendimento
--     antes de gerar os novos.
-- =============================================================================

create or replace function gera_creditos(p_atendimento integer)
returns integer as $$
declare
    v_atendimento atendimentos%rowtype;
    v_parcelas    integer;
    v_a_vista     boolean;
    v_valor_parc  numeric(10,2);
    v_diferenca   numeric(10,2);
    v_valor       numeric(10,2);
    v_vencimento  date;
    v_pagamento   date;
    i             integer;
begin
    select * into v_atendimento
      from atendimentos
     where codigo = p_atendimento;

    if not found then
        raise exception 'atendimento % não encontrado.', p_atendimento;
    end if;

    if coalesce(v_atendimento.total, 0) <= 0 then
        raise exception 'atendimento % não possui valor total a receber.', p_atendimento;
    end if;

    -- permite reprocessar o atendimento sem duplicar créditos
    delete from recebimentos where atendimento = p_atendimento;

    v_a_vista := lower(coalesce(v_atendimento.condicao, 'v')) = 'v'
             and coalesce(v_atendimento.nro_parcelas, 1) = 1
             and coalesce(v_atendimento.prazo, 0) = 0;

    if v_a_vista then
        v_parcelas  := 1;
        v_pagamento := v_atendimento.data;
    else
        v_parcelas  := greatest(coalesce(v_atendimento.nro_parcelas, 1), 1);
        v_pagamento := null;
    end if;

    -- parcelas iguais; o que sobrar do arredondamento entra na última
    v_valor_parc := trunc(v_atendimento.total / v_parcelas, 2);
    v_diferenca  := v_atendimento.total - (v_valor_parc * v_parcelas);

    for i in 1 .. v_parcelas loop
        v_valor := v_valor_parc;

        if i = v_parcelas then
            v_valor := v_valor + v_diferenca;
        end if;

        v_vencimento := (v_atendimento.data + ((i - 1) * interval '1 month'))::date;

        insert into recebimentos (codigo, atendimento, vencimento, valor, pagamento)
        values (i, p_atendimento, v_vencimento, v_valor, v_pagamento);
    end loop;

    return v_parcelas;
end;
$$ language plpgsql;

comment on function gera_creditos(integer)
     is 'gera os recebimentos (créditos) de um atendimento e retorna quantas parcelas foram criadas.';
