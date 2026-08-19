-- ============================================================
-- Exercícios de funções - 01
-- ============================================================
-- Este script é autossuficiente: cria a tabela "pessoas" do zero,
-- insere alguns dados de teste e resolve os 3 exercícios pedidos.
--
-- COMO USAR NO pgAdmin:
--   1. Abra (ou crie) o banco de dados onde você quer trabalhar.
--   2. Clique com botão direito no banco -> "Query Tool".
--   3. Cole TODO este arquivo na área de consulta.
--   4. Rode tudo de uma vez com o botão ▶ (Execute/Refresh, ou F5).
--   5. Veja a aba "Messages" para confirmar que rodou sem erro.
--   6. Os SELECTs finais aparecem na aba "Data Output".
-- ============================================================


-- ------------------------------------------------------------
-- 0) Criação da tabela base "pessoas"
-- ------------------------------------------------------------
-- Se você já tem uma tabela "pessoas" de outro exercício, avise
-- que a gente ajusta este script para reaproveitá-la em vez de
-- recriar. Aqui criamos do zero para não depender de nada.

DROP TABLE IF EXISTS pessoas;

CREATE TABLE pessoas (
    codigo      INT         NOT NULL,
    nome        VARCHAR(60) NOT NULL,
    tipo_pessoa CHAR(1)     NOT NULL DEFAULT 'F',   -- F = Física, J = Jurídica
    cpf         VARCHAR(11),
    cnpj        VARCHAR(14),
    nascimento  DATE,

    CONSTRAINT pk_pessoas PRIMARY KEY (codigo),
    CONSTRAINT chk_pessoas_tipo_pessoa CHECK (tipo_pessoa IN ('F', 'J'))
);

-- Pessoas físicas (têm CPF e data de nascimento)
INSERT INTO pessoas (codigo, nome, tipo_pessoa, cpf, nascimento) VALUES
    (1, 'Ana Souza',     'F', '11122233344', '1995-03-21'),
    (2, 'Carlos Lima',   'F', '22233344455', '1988-07-02'),
    (3, 'Pedro Alves',   'F', '33344455566', '2000-10-12');

-- Pessoas jurídicas (têm CNPJ, sem data de nascimento)
INSERT INTO pessoas (codigo, nome, tipo_pessoa, cnpj) VALUES
    (4, 'Comercio Silva LTDA',     'J', '12345678000199'),
    (5, 'Distribuidora Nova S/A',  'J', '98765432000188');

SELECT * FROM pessoas;


-- ------------------------------------------------------------
-- 1) Função que retorna o maior código + 1 da tabela de pessoas
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION f_proximo_codigo_pessoa()
RETURNS INTEGER
AS
$$
DECLARE
    v_codigo INTEGER;
BEGIN
    SELECT COALESCE(MAX(codigo), 0) + 1
    INTO v_codigo
    FROM pessoas;

    RETURN v_codigo;
END;
$$
LANGUAGE 'plpgsql';

-- Teste:
SELECT f_proximo_codigo_pessoa();


-- ------------------------------------------------------------
-- 2) Função que calcula a idade a partir da data de nascimento
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION f_calcula_idade(p_nascimento DATE)
RETURNS INTEGER
AS
$$
DECLARE
    v_idade INTEGER;
BEGIN
    v_idade = EXTRACT(YEAR FROM AGE(CURRENT_DATE, p_nascimento));
    RETURN v_idade;
END;
$$
LANGUAGE 'plpgsql';

-- Teste (só faz sentido para quem tem nascimento preenchido):
SELECT codigo, nome, nascimento, f_calcula_idade(nascimento) AS idade
FROM pessoas
WHERE nascimento IS NOT NULL;


-- ------------------------------------------------------------
-- 3) Função que retorna o CPF ou CNPJ, conforme o tipo_pessoa
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION f_identificacao_pessoa(p_codigo INTEGER)
RETURNS VARCHAR
AS
$$
DECLARE
    v_tipo   CHAR(1);
    v_cpf    VARCHAR(11);
    v_cnpj   VARCHAR(14);
    v_result VARCHAR(14);
BEGIN
    SELECT tipo_pessoa, cpf, cnpj
    INTO v_tipo, v_cpf, v_cnpj
    FROM pessoas
    WHERE codigo = p_codigo;

    IF v_tipo = 'F' THEN
        v_result = v_cpf;
    ELSE
        v_result = v_cnpj;
    END IF;

    RETURN v_result;
END;
$$
LANGUAGE 'plpgsql';

-- Teste pedido no exercício: nome da pessoa + identificação (cpf ou cnpj)
SELECT nome, f_identificacao_pessoa(codigo) AS identificacao
FROM pessoas;
