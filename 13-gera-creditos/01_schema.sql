-- =============================================================================
-- Exercício: Laços com banco de dados - geração de créditos (recebimentos)
-- Arquivo: 01_schema.sql
-- Estrutura mínima necessária para o exercício (PostgreSQL).
-- =============================================================================

CREATE TABLE IF NOT EXISTS pessoas (
    codigo SERIAL PRIMARY KEY,
    nome   VARCHAR(60) NOT NULL
);

CREATE TABLE IF NOT EXISTS atendimentos (
    codigo            SERIAL PRIMARY KEY,
    data              DATE          NOT NULL DEFAULT CURRENT_DATE,
    condicao          CHARACTER(1)  NOT NULL DEFAULT 'V',
    total             NUMERIC(10,2) NOT NULL DEFAULT 0,
    pessoa_funcionario INTEGER REFERENCES pessoas (codigo),
    pessoa_cliente     INTEGER REFERENCES pessoas (codigo),
    pessoa_tecnico     INTEGER REFERENCES pessoas (codigo)
);

-- ---------------------------------------------------------------------------
-- Pedido do enunciado: criar os campos nro_parcelas e prazo em atendimentos.
-- ---------------------------------------------------------------------------
ALTER TABLE atendimentos ADD COLUMN IF NOT EXISTS nro_parcelas INTEGER NOT NULL DEFAULT 1;
ALTER TABLE atendimentos ADD COLUMN IF NOT EXISTS prazo        INTEGER NOT NULL DEFAULT 0;

ALTER TABLE atendimentos DROP CONSTRAINT IF EXISTS atendimentos_nro_parcelas_ck;
ALTER TABLE atendimentos ADD  CONSTRAINT atendimentos_nro_parcelas_ck CHECK (nro_parcelas >= 1);

ALTER TABLE atendimentos DROP CONSTRAINT IF EXISTS atendimentos_prazo_ck;
ALTER TABLE atendimentos ADD  CONSTRAINT atendimentos_prazo_ck CHECK (prazo >= 0);

ALTER TABLE atendimentos DROP CONSTRAINT IF EXISTS atendimentos_condicao_ck;
ALTER TABLE atendimentos ADD  CONSTRAINT atendimentos_condicao_ck CHECK (UPPER(condicao) IN ('V', 'P'));

COMMENT ON COLUMN atendimentos.condicao     IS 'Condição de pagamento: V = à vista, P = a prazo';
COMMENT ON COLUMN atendimentos.nro_parcelas IS 'Em quantas parcelas o atendimento será recebido';
COMMENT ON COLUMN atendimentos.prazo        IS 'Prazo do atendimento; 0 identifica venda à vista';

-- ---------------------------------------------------------------------------
-- Créditos gerados a partir do atendimento.
-- A PK é composta: cada atendimento numera suas parcelas a partir de 1.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS recebimentos (
    codigo      INTEGER       NOT NULL,
    atendimento INTEGER       NOT NULL REFERENCES atendimentos (codigo) ON DELETE CASCADE,
    vencimento  DATE          NOT NULL,
    valor       NUMERIC(10,2) NOT NULL,
    pagamento   DATE,
    CONSTRAINT recebimentos_pk    PRIMARY KEY (codigo, atendimento),
    CONSTRAINT recebimentos_valor_ck CHECK (valor > 0)
);
