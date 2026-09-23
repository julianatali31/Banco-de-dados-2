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

-- teste:
select f_soma_dano_cultura('2026-09-23', '2026-09-30', 10);
select f_soma_dano_cultura('2026-09-23', '2026-09-30', 60);
select f_soma_dano_cultura('2026-09-23', '2026-09-30', 20);


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

-- teste:
select f_gerar_lancamentos('2026-09-23', '2026-09-30', 10, 60, 20);


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

-- teste:
select * from f_cultura_maior_dano('2026-09-23', '2026-09-30');
