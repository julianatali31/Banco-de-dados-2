-- ============================================================
-- questao 1 - crie um banco de dados com as tabelas do modelo
-- ============================================================

create table insetos (
    codigo integer not null,
    nome   text    not null,
    primary key (codigo)
);

create table culturas (
    codigo    integer not null,
    descricao text    not null,
    primary key (codigo)
);

create table insetos_danos (
    inseto     integer      not null,
    cultura    integer      not null,
    valor_dano numeric(12,2) not null,
    primary key (inseto, cultura),
    foreign key (inseto) references insetos (codigo),
    foreign key (cultura) references culturas (codigo)
);

create table lancamentos (
    codigo     bigserial     not null,
    data       date          not null,
    inseto     integer       not null,
    cultura    integer       not null,
    quantidade integer       not null,
    valor_dano numeric(12,2) not null,
    total_dano numeric(12,2) not null,
    primary key (codigo),
    foreign key (inseto) references insetos (codigo),
    foreign key (cultura) references culturas (codigo)
);


-- ============================================================
-- dados de exemplo (para testar as funcoes abaixo)
-- ============================================================

insert into insetos (codigo, nome) values
    (60, 'lagarta-do-cartucho'),
    (15, 'percevejo'),
    (30, 'pulgao');

insert into culturas (codigo, descricao) values
    (10, 'soja'),
    (20, 'milho'),
    (60, 'trigo');

insert into insetos_danos (inseto, cultura, valor_dano) values
    (60, 10, 15.50), -- lagarta na soja
    (15, 20, 8.00),  -- percevejo no milho
    (30, 60, 5.25);  -- pulgao no trigo


-- ============================================================
-- questao 5 - soma do total de danos de uma cultura num periodo
-- ============================================================

create or replace function f_soma_dano_cultura(
    p_data_inicio date,
    p_data_fim    date,
    p_cultura     integer
)
returns numeric
as
$$
declare
    v_soma numeric(12,2);
begin
    select coalesce(sum(total_dano), 0)
    into v_soma
    from lancamentos
    where cultura = p_cultura
      and data between p_data_inicio and p_data_fim;

    return v_soma;
end;
$$
language 'plpgsql';

-- teste: ver a secao "executando os testes" no final do arquivo
-- (essa funcao so retorna valor depois que a questao 6 gerar os lancamentos)


-- ============================================================
-- questao 6 - gera os lancamentos diarios de um periodo
-- ============================================================

create or replace function f_gerar_lancamentos(
    p_data_inicio date,
    p_data_fim    date,
    p_cultura     integer,
    p_inseto      integer,
    p_quantidade  integer
)
returns void
as
$$
declare
    v_data       date;
    v_valor_dano numeric(12,2);
begin
    select valor_dano
    into v_valor_dano
    from insetos_danos
    where inseto = p_inseto
      and cultura = p_cultura;

    v_data := p_data_inicio;

    while v_data <= p_data_fim loop
        insert into lancamentos (data, inseto, cultura, quantidade, valor_dano, total_dano)
        values (v_data, p_inseto, p_cultura, p_quantidade, v_valor_dano, p_quantidade * v_valor_dano);

        v_data := v_data + 1;
    end loop;
end;
$$
language 'plpgsql';

-- teste: ver a secao "executando os testes" no final do arquivo


-- ============================================================
-- questao 7 - cultura de maior dano num periodo, usando cursor
-- ============================================================

create or replace function f_cultura_maior_dano(
    p_data_inicio date,
    p_data_fim    date,
    out p_cultura integer,
    out p_valor   numeric
)
as
$$
declare
    cur_culturas cursor for
        select cultura, sum(total_dano) as soma
        from lancamentos
        where data between p_data_inicio and p_data_fim
        group by cultura;

    v_cultura integer;
    v_soma    numeric(12,2);
begin
    p_valor := 0;

    open cur_culturas;

    loop
        fetch cur_culturas into v_cultura, v_soma;
        exit when not found;

        if v_soma > p_valor then
            p_cultura := v_cultura;
            p_valor   := v_soma;
        end if;
    end loop;

    close cur_culturas;
end;
$$
language 'plpgsql';

-- teste: ver a secao "executando os testes" no final do arquivo


-- ============================================================
-- executando os testes (ordem importa: primeiro gera os dados
-- com a funcao da questao 6, depois testa as questoes 5 e 7)
-- ============================================================

-- questao 6: gera lancamentos para as 3 culturas de exemplo, de 23/09 a 30/09/2026
select f_gerar_lancamentos('2026-09-23', '2026-09-30', 10, 60, 20); -- soja, lagarta, qtd 20/dia
select f_gerar_lancamentos('2026-09-23', '2026-09-30', 20, 15, 10); -- milho, percevejo, qtd 10/dia
select f_gerar_lancamentos('2026-09-23', '2026-09-30', 60, 30, 50); -- trigo, pulgao, qtd 50/dia

-- conferindo os lancamentos gerados:
select * from lancamentos order by cultura, data;

-- questao 5: soma do dano por cultura no periodo
select f_soma_dano_cultura('2026-09-23', '2026-09-30', 10); -- soja
select f_soma_dano_cultura('2026-09-23', '2026-09-30', 20); -- milho
select f_soma_dano_cultura('2026-09-23', '2026-09-30', 60); -- trigo

-- questao 7: cultura de maior dano no periodo (usando cursor)
select * from f_cultura_maior_dano('2026-09-23', '2026-09-30');
