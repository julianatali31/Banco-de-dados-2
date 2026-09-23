-- Banco de dados: controle de danos de insetos em culturas

CREATE TABLE insetos (
    codigo INTEGER NOT NULL,
    nome TEXT NOT NULL,
    PRIMARY KEY (codigo)
);

CREATE TABLE culturas (
    codigo INTEGER NOT NULL,
    descricao TEXT NOT NULL,
    PRIMARY KEY (codigo)
);

CREATE TABLE insetos_danos (
    inseto INTEGER NOT NULL,
    cultura INTEGER NOT NULL,
    valor_dano NUMERIC(12,2) NOT NULL,
    PRIMARY KEY (inseto, cultura),
    FOREIGN KEY (inseto) REFERENCES insetos (codigo),
    FOREIGN KEY (cultura) REFERENCES culturas (codigo)
);

CREATE TABLE lancamentos (
    codigo BIGSERIAL NOT NULL,
    data DATE NOT NULL,
    inseto INTEGER NOT NULL,
    cultura INTEGER NOT NULL,
    quantidade INTEGER NOT NULL,
    valor_dano NUMERIC(12,2) NOT NULL,
    total_dano NUMERIC(12,2) NOT NULL,
    PRIMARY KEY (codigo),
    FOREIGN KEY (inseto) REFERENCES insetos (codigo),
    FOREIGN KEY (cultura) REFERENCES culturas (codigo)
);
