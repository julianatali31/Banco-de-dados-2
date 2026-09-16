-- =============================================================================
-- Exercício: Laços com banco de dados - geração de créditos (recebimentos)
-- Arquivo: 02_funcao_gera_creditos.sql
--
-- gera_creditos(codigo do atendimento) percorre, com um laço, o número de
-- parcelas do atendimento e grava um registro em recebimentos para cada uma.
--
-- Regras adotadas:
--   * É à vista quando condicao = 'V' E nro_parcelas = 1 E prazo = 0.
--     Nesse caso gera uma única parcela já quitada (pagamento = data).
--   * A prazo, a 1a parcela vence na data do atendimento (entrada) e as
--     demais de mês em mês; o pagamento fica em aberto (NULL).
--   * O valor é dividido igualmente; a diferença de arredondamento vai
--     para a última parcela, de modo que a soma feche com o total.
--   * A função é idempotente: apaga os créditos anteriores do atendimento
--     antes de gerar os novos.
-- =============================================================================

CREATE OR REPLACE FUNCTION gera_creditos(p_atendimento INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_atendimento  atendimentos%ROWTYPE;
    v_parcelas     INTEGER;
    v_a_vista      BOOLEAN;
    v_valor_parc   NUMERIC(10,2);
    v_diferenca    NUMERIC(10,2);
    v_valor        NUMERIC(10,2);
    v_vencimento   DATE;
    v_pagamento    DATE;
    i              INTEGER;
BEGIN
    SELECT * INTO v_atendimento
      FROM atendimentos
     WHERE codigo = p_atendimento;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Atendimento % não encontrado.', p_atendimento;
    END IF;

    IF COALESCE(v_atendimento.total, 0) <= 0 THEN
        RAISE EXCEPTION 'Atendimento % não possui valor total a receber.', p_atendimento;
    END IF;

    -- permite reprocessar o atendimento sem duplicar créditos
    DELETE FROM recebimentos WHERE atendimento = p_atendimento;

    v_a_vista := UPPER(COALESCE(v_atendimento.condicao, 'V')) = 'V'
             AND COALESCE(v_atendimento.nro_parcelas, 1) = 1
             AND COALESCE(v_atendimento.prazo, 0) = 0;

    IF v_a_vista THEN
        v_parcelas  := 1;
        v_pagamento := v_atendimento.data;
    ELSE
        v_parcelas  := GREATEST(COALESCE(v_atendimento.nro_parcelas, 1), 1);
        v_pagamento := NULL;
    END IF;

    -- parcelas iguais; o que sobrar do arredondamento entra na última
    v_valor_parc := TRUNC(v_atendimento.total / v_parcelas, 2);
    v_diferenca  := v_atendimento.total - (v_valor_parc * v_parcelas);

    FOR i IN 1 .. v_parcelas LOOP
        v_valor := v_valor_parc;

        IF i = v_parcelas THEN
            v_valor := v_valor + v_diferenca;
        END IF;

        v_vencimento := (v_atendimento.data + ((i - 1) * INTERVAL '1 month'))::DATE;

        INSERT INTO recebimentos (codigo, atendimento, vencimento, valor, pagamento)
        VALUES (i, p_atendimento, v_vencimento, v_valor, v_pagamento);
    END LOOP;

    RETURN v_parcelas;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION gera_creditos(INTEGER)
     IS 'Gera os recebimentos (créditos) de um atendimento e retorna quantas parcelas foram criadas.';
