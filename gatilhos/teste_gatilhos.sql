-- Script de teste dos gatilhos (rodar depois de exercicio_gatilhos.sql)
INSERT INTO produtos VALUES (1,'Brigadeiro',2.50,100),(2,'Beijinho',3.00,50);
INSERT INTO vendas (codigo) VALUES (1),(2);

\echo '--- INSERT: 10x prod1 e 5x prod2 na venda 1 (esperado total 40.00, estoque 90/45)'
INSERT INTO vendas_produtos (venda, produto, quantidade) VALUES (1,1,10),(1,2,5);
SELECT * FROM vendas_produtos ORDER BY codigo;
SELECT * FROM produtos ORDER BY codigo;
SELECT * FROM vendas ORDER BY codigo;

\echo '--- UPDATE: item 1 vira 20x (esperado total 65.00, estoque prod1 80)'
UPDATE vendas_produtos SET quantidade = 20 WHERE codigo = 1;
SELECT * FROM produtos ORDER BY codigo;
SELECT * FROM vendas ORDER BY codigo;

\echo '--- UPDATE: item 2 muda p/ venda 2 e produto 1 (esperado v1=50.00, v2=12.50, estoque 1=75, 2=50)'
UPDATE vendas_produtos SET venda = 2, produto = 1 WHERE codigo = 2;
SELECT * FROM vendas_produtos ORDER BY codigo;
SELECT * FROM produtos ORDER BY codigo;
SELECT * FROM vendas ORDER BY codigo;

\echo '--- DELETE dos itens (esperado totais 0, estoques 100/50)'
DELETE FROM vendas_produtos;
SELECT * FROM produtos ORDER BY codigo;
SELECT * FROM vendas ORDER BY codigo;
