-- =============================================================================
-- exercício: laços com banco de dados - geração de créditos (recebimentos)
-- arquivo: 01_schema.sql
-- estrutura mínima necessária para o exercício (postgresql).
-- =============================================================================

create table if not exists pessoas (
    codigo serial primary key,
    nome   varchar(60) not null
);

create table if not exists atendimentos (
    codigo             serial primary key,
    data               date          not null default current_date,
    condicao           character(1)  not null default 'v',
    total              numeric(10,2) not null default 0,
    pessoa_funcionario integer references pessoas (codigo),
    pessoa_cliente     integer references pessoas (codigo),
    pessoa_tecnico     integer references pessoas (codigo)
);

-- ---------------------------------------------------------------------------
-- pedido do enunciado: criar os campos nro_parcelas e prazo em atendimentos.
-- ---------------------------------------------------------------------------
alter table atendimentos add column if not exists nro_parcelas integer not null default 1;
alter table atendimentos add column if not exists prazo        integer not null default 0;

alter table atendimentos drop constraint if exists atendimentos_nro_parcelas_ck;
alter table atendimentos add  constraint atendimentos_nro_parcelas_ck check (nro_parcelas >= 1);

alter table atendimentos drop constraint if exists atendimentos_prazo_ck;
alter table atendimentos add  constraint atendimentos_prazo_ck check (prazo >= 0);

alter table atendimentos drop constraint if exists atendimentos_condicao_ck;
alter table atendimentos add  constraint atendimentos_condicao_ck check (lower(condicao) in ('v', 'p'));

comment on column atendimentos.condicao     is 'condição de pagamento: v = à vista, p = a prazo';
comment on column atendimentos.nro_parcelas is 'em quantas parcelas o atendimento será recebido';
comment on column atendimentos.prazo        is 'prazo do atendimento; 0 identifica venda à vista';

-- ---------------------------------------------------------------------------
-- créditos gerados a partir do atendimento.
-- a pk é composta: cada atendimento numera suas parcelas a partir de 1.
-- ---------------------------------------------------------------------------
create table if not exists recebimentos (
    codigo      integer       not null,
    atendimento integer       not null references atendimentos (codigo) on delete cascade,
    vencimento  date          not null,
    valor       numeric(10,2) not null,
    pagamento   date,
    constraint recebimentos_pk       primary key (codigo, atendimento),
    constraint recebimentos_valor_ck check (valor > 0)
);
