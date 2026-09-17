-- =====================================================================================
--  ARQUIVO 5:  AS CINCO PERGUNTAS DE NEGOCIO
--  Case: Pata Amiga - rede de petshops de SC  |  MySQL 8.0
-- =====================================================================================
--  Rode depois de: 04-fato.sql
--
--  Cada pergunta e UMA consulta: um SELECT com JOIN e GROUP BY. A subconsulta
--  aparece na P2 e na P5, e serve para trazer o total da rede como denominador.
-- =====================================================================================

USE dw_pata_amiga;

-- =====================================================================================
--  P1 - ONDE ESTA O GARGALO DO PROCESSO DE ENTREGA?
-- =====================================================================================
--  Media (AVG) dos quatro intervalos ja calculados na carga, agrupada por porte
--  de loja. AVG ignora NULL - por isso a etapa nao cumprida foi gravada como NULL.
--  dias_total_ate_entrega e o processo inteiro, nao um dos quatro intervalos.

-- P1 - gargalos por porte
SELECT
    l.porte,
    ROUND(AVG(f.dias_integracao_separacao), 2) AS media_integracao_separacao,
    ROUND(AVG(f.dias_separacao_nota), 2) AS media_separacao_nota,
    ROUND(AVG(f.dias_nota_despacho), 2) AS media_nota_despacho,
    ROUND(AVG(f.dias_despacho_entrega), 2) AS media_despacho_entrega,
    ROUND(AVG(f.dias_total_ate_entrega), 2) AS media_total_ate_entrega,
    CASE
        WHEN AVG(f.dias_integracao_separacao) >= AVG(f.dias_separacao_nota)
         AND AVG(f.dias_integracao_separacao) >= AVG(f.dias_nota_despacho)
         AND AVG(f.dias_integracao_separacao) >= AVG(f.dias_despacho_entrega)
            THEN 'Integracao -> Separacao'
        WHEN AVG(f.dias_separacao_nota) >= AVG(f.dias_integracao_separacao)
         AND AVG(f.dias_separacao_nota) >= AVG(f.dias_nota_despacho)
         AND AVG(f.dias_separacao_nota) >= AVG(f.dias_despacho_entrega)
            THEN 'Separacao -> Nota Fiscal'
        WHEN AVG(f.dias_nota_despacho) >= AVG(f.dias_integracao_separacao)
         AND AVG(f.dias_nota_despacho) >= AVG(f.dias_separacao_nota)
         AND AVG(f.dias_nota_despacho) >= AVG(f.dias_despacho_entrega)
            THEN 'Nota Fiscal -> Despacho'
        ELSE 'Despacho -> Entrega'
    END AS etapa_gargalo
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
WHERE l.sk_loja <> -1
GROUP BY l.porte
ORDER BY l.porte;



-- =====================================================================================
--  P2 - QUAL CATEGORIA CONCENTRA O FATURAMENTO?
-- =====================================================================================
--  Esta e a pergunta que paga a dim_categoria. Agrupe pelo nome_categoria
--  PADRONIZADO (nunca pela grafia crua). O percentual do total usa uma
--  subconsulta com o faturamento da rede como denominador.

-- P2 - faturamento por categoria padronizada e percentual do total
SELECT
    c.nome_categoria,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento,
    ROUND(100 * SUM(f.vl_liquido) /
        (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS percentual_total
FROM fato_pedido f
JOIN dim_categoria c ON c.sk_categoria = f.sk_categoria
GROUP BY c.nome_categoria
ORDER BY faturamento DESC;



-- =====================================================================================
--  P3 - O DESCONTO FUNCIONA IGUAL EM TODO CANAL?
-- =====================================================================================
--  Aqui NAO ha JOIN: desconto e canal foram padronizados na carga e moram na
--  propria fato. Compare o TICKET MEDIO com e sem desconto DENTRO de cada canal.
--  Confira se o WhatsApp aparece - se nao, o CASE do arquivo 04 testou APP antes
--  de WHATS.

-- P3 - ticket medio com/sem desconto e participacao de cada canal
SELECT
    canal_pedido,
    ROUND(
        AVG(CASE 
            WHEN houve_desconto = 'Sim' 
            THEN vl_liquido END), 2) AS ticket_com_desconto,
    ROUND(
        AVG(CASE WHEN houve_desconto = 'Nao' 
        THEN vl_liquido END),2) AS ticket_sem_desconto,

    ROUND( 100 * SUM(vl_liquido) /  (SELECT SUM(vl_liquido)
         FROM fato_pedido
         WHERE canal_pedido <> 'Nao Informado'), 2 ) AS percentual_faturamento

FROM fato_pedido
WHERE canal_pedido <> 'Nao Informado'
GROUP BY canal_pedido
ORDER BY SUM(vl_liquido) DESC;


-- =====================================================================================
--  P4 - QUAL PRACA DE ATENDIMENTO CONCENTRA O FATURAMENTO?
-- =====================================================================================
--  Esta e a pergunta que paga a dim_praca e a ponte.
--  Caminho: fato_pedido -> dim_loja -> bridge_loja_praca -> dim_praca (a ponte
--  entra pelo cod_loja). O JOIN com a ponte DUPLICA a linha do pedido, uma por
--  praca - isso esta certo. Multiplique por b.fator_publico para o faturamento
--  nao ser contado duas vezes.

-- P4 - faturamento rateado por praca
SELECT
    p.nome_praca,
    p.regional,
    ROUND(SUM(f.vl_liquido * b.fator_publico), 2) AS faturamento_rateado,
    MAX(p.domicilios_com_pet) AS domicilios_com_pet
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
JOIN bridge_loja_praca b ON b.cod_loja = l.cod_loja
JOIN dim_praca p ON p.sk_praca = b.sk_praca
WHERE f.sk_loja <> -1
GROUP BY p.sk_praca, p.nome_praca, p.regional
ORDER BY faturamento_rateado DESC;


-- =====================================================================================
--  P5 - ONDE ABRIR A PROXIMA LOJA, E O QUE OS DADOS NAO PERMITEM AFIRMAR?
-- =====================================================================================
--  (a) Ranqueie as lojas por itens POR MIL HABITANTES (numerador na fato,
--      denominador na dimensao), calculado AQUI na consulta - nunca gravado
--      pronto. Cruze com o tempo medio de entrega.
--  (b) Mostre o faturamento por faixa de franquia e explique por que ele NAO
--      responde "quanto veio de lojas que JA ERAM Ouro na data do pedido": o
--      cadastro so tem a foto de hoje.
--  (c) Meca o que ficou de fora: pedidos sem loja, entregas nao concluidas,
--      itens e valores em branco.

-- P5(a) - ranking por itens por mil habitantes + tempo medio de entrega
SELECT
    l.cod_loja,
    l.nome_loja,
    l.cidade,
    l.porte,
    l.populacao_cidade,
    SUM(f.qt_itens) AS itens_vendidos,
    ROUND(1000 * SUM(f.qt_itens) / l.populacao_cidade, 2) AS itens_por_mil_habitantes,
    ROUND(AVG(f.dias_total_ate_entrega), 2) AS tempo_medio_entrega
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
WHERE l.sk_loja <> -1
  AND l.populacao_cidade IS NOT NULL
GROUP BY l.sk_loja, l.cod_loja, l.nome_loja, l.cidade, l.porte, l.populacao_cidade
ORDER BY itens_por_mil_habitantes DESC;

-- P5(b) - faturamento por faixa de franquia ATUAL
SELECT
    l.faixa_franquia,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento_atual
FROM fato_pedido f
JOIN dim_loja l ON l.sk_loja = f.sk_loja
WHERE l.sk_loja <> -1
GROUP BY l.faixa_franquia
ORDER BY faturamento_atual DESC;

-- P5(c) - dados excluidos / incompletos
SELECT
    (SELECT COUNT(*) FROM fato_pedido WHERE sk_loja = -1) AS pedidos_sem_loja,
    (SELECT COUNT(*) FROM fato_pedido WHERE sk_tempo_entrega = -1) AS entregas_nao_concluidas,
    (SELECT COUNT(*) FROM fato_pedido WHERE qt_itens IS NULL) AS pedidos_com_itens_em_branco,
    (SELECT COUNT(*) FROM fato_pedido WHERE vl_liquido IS NULL) AS pedidos_com_valor_em_branco;

