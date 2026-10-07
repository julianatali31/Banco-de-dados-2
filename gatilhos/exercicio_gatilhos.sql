-- ============================================================
-- Exercícios Gatilhos (PostgreSQL)
-- Modelo: produtos, vendas, vendas_produtos
-- ============================================================

-- ------------------------------------------------------------
-- 1. Implementação do banco de dados
-- ------------------------------------------------------------
DROP TABLE IF EXISTS vendas_produtos;
DROP TABLE IF EXISTS vendas;
DROP TABLE IF EXISTS produtos;

CREATE TABLE produtos (
    codigo  integer       PRIMARY KEY,
    nome    varchar(100)  NOT NULL,
    preco   numeric(10,2) NOT NULL CHECK (preco >= 0),
    estoque integer       NOT NULL DEFAULT 0
);

CREATE TABLE vendas (
    codigo integer       PRIMARY KEY,
    data   date          NOT NULL DEFAULT current_date,
    total  numeric(12,2) NOT NULL DEFAULT 0
);

CREATE TABLE vendas_produtos (
    codigo         integer       PRIMARY KEY,
    venda          integer       NOT NULL REFERENCES vendas (codigo),
    produto        integer       NOT NULL REFERENCES produtos (codigo),
    quantidade     integer       NOT NULL CHECK (quantidade > 0),
    valor_unitario numeric(10,2),
    valor_total    numeric(12,2)
);

-- ------------------------------------------------------------
-- 2. Gatilhos
-- Obs.: gatilhos do mesmo evento disparam em ordem alfabética
-- do nome; por isso os prefixos 01, 02, 03 nos BEFORE.
-- ------------------------------------------------------------

-- 2.1 Gera o código de vendas_produtos (maior valor + 1) ------
CREATE OR REPLACE FUNCTION gera_codigo_vendas_produtos() RETURNS trigger
AS
$$
BEGIN
    SELECT COALESCE(MAX(codigo), 0) + 1
      INTO new.codigo
      FROM vendas_produtos;
    RETURN new;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER vp_01_gera_codigo
    BEFORE INSERT
    ON vendas_produtos
    FOR EACH ROW
    EXECUTE PROCEDURE gera_codigo_vendas_produtos();

-- 2.2 Traz o preço do produto para valor_unitario -------------
CREATE OR REPLACE FUNCTION traz_preco_produto() RETURNS trigger
AS
$$
BEGIN
    -- no UPDATE só busca o preço de novo se o produto mudou
    IF (tg_op = 'INSERT' OR new.produto <> old.produto) THEN
        SELECT preco
          INTO new.valor_unitario
          FROM produtos
         WHERE codigo = new.produto;
    END IF;
    RETURN new;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER vp_02_traz_preco
    BEFORE INSERT OR UPDATE
    ON vendas_produtos
    FOR EACH ROW
    EXECUTE PROCEDURE traz_preco_produto();

-- 2.3 Calcula valor_total = quantidade * valor_unitario -------
CREATE OR REPLACE FUNCTION calcula_valor_total() RETURNS trigger
AS
$$
BEGIN
    new.valor_total := new.quantidade * new.valor_unitario;
    RETURN new;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER vp_03_calcula_total
    BEFORE INSERT OR UPDATE
    ON vendas_produtos
    FOR EACH ROW
    EXECUTE PROCEDURE calcula_valor_total();

-- 2.4 Atualiza o estoque do produto vendido -------------------
CREATE OR REPLACE FUNCTION atualiza_estoque() RETURNS trigger
AS
$$
BEGIN
    IF (tg_op = 'INSERT') THEN
        UPDATE produtos SET estoque = estoque - new.quantidade
         WHERE codigo = new.produto;
        RETURN new;
    END IF;

    IF (tg_op = 'DELETE') THEN
        UPDATE produtos SET estoque = estoque + old.quantidade
         WHERE codigo = old.produto;
        RETURN old;
    END IF;

    IF (tg_op = 'UPDATE') THEN
        -- devolve a quantidade antiga e retira a nova
        -- (cobre também a troca de produto)
        UPDATE produtos SET estoque = estoque + old.quantidade
         WHERE codigo = old.produto;
        UPDATE produtos SET estoque = estoque - new.quantidade
         WHERE codigo = new.produto;
        RETURN new;
    END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER vp_estoque
    AFTER INSERT OR UPDATE OR DELETE
    ON vendas_produtos
    FOR EACH ROW
    EXECUTE PROCEDURE atualiza_estoque();

-- 2.5 Atualiza o total das vendas -----------------------------
CREATE OR REPLACE FUNCTION atualiza_total_venda() RETURNS trigger
AS
$$
BEGIN
    IF (tg_op = 'INSERT') THEN
        UPDATE vendas SET total = total + new.valor_total
         WHERE codigo = new.venda;
        RETURN new;
    END IF;

    IF (tg_op = 'DELETE') THEN
        UPDATE vendas SET total = total - old.valor_total
         WHERE codigo = old.venda;
        RETURN old;
    END IF;

    IF (tg_op = 'UPDATE') THEN
        -- tira o valor antigo da venda antiga e soma o novo na nova
        UPDATE vendas SET total = total - old.valor_total
         WHERE codigo = old.venda;
        UPDATE vendas SET total = total + new.valor_total
         WHERE codigo = new.venda;
        RETURN new;
    END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER vp_total_venda
    AFTER INSERT OR UPDATE OR DELETE
    ON vendas_produtos
    FOR EACH ROW
    EXECUTE PROCEDURE atualiza_total_venda();
