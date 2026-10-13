WITH tb_transacoes AS (
    SELECT *
    FROM workspace.tmw_loyalty.transacoes
    WHERE DtCriacao < '{date}'
    AND DtCriacao >= '{date}' - interval 28 days
),

tb_cliente_agg AS (

    SELECT IdCliente,
        count(distinct date(DtCriacao)) AS qtFrequencia,
        sum(QtdePontos) AS qtPontos,
        sum(CASE WHEN QtdePontos > 0 THEN QtdePontos ELSE 0 END) AS qtPontosPositivos,
        min(date_diff('{date}', DtCriacao)) AS recencia,
        count(idTransacao) AS QtdeTransacoes
    FROM tb_transacoes

    GROUP BY ALL
),

tb_cliente_produto AS (

    SELECT IdCliente,
            count(DISTINCT CASE WHEN t3.DescNomeProduto = 'ChatMessage' then t1.idTransacao else null end) / count(DISTINCT t1.IdTransacao)  AS pctTransacaoChatMessage,
            count(DISTINCT CASE WHEN t3.DescNomeProduto = 'Lista de presença' then t1.idTransacao else null end) / count(DISTINCT t1.IdTransacao)  AS pctTransacaoListapresenca,
            count(DISTINCT CASE WHEN t3.DescNomeProduto = 'Presença Streak' then t1.idTransacao else null end) / count(DISTINCT t1.IdTransacao)  AS pctTransacaoPresencaStreak,
            count(DISTINCT CASE WHEN t3.DescNomeProduto = 'Resgatar Ponei' then t1.idTransacao else null end) / count(DISTINCT t1.IdTransacao)  AS pctTransacaoResgatarPonei,
            count(DISTINCT CASE WHEN t3.DescNomeProduto = 'Troca de Pontos StreamElements' then t1.idTransacao else null end) / count(DISTINCT t1.IdTransacao)  AS pctTransacaoTrocaPontosStreamElements,
            max(CASE WHEN t3.DescNomeProduto = 'Presença Streak' then 1 else 0 end) as flStreak,
            min(CASE WHEN t3.DescNomeProduto = 'Presença Streak' THEN date_diff('{date}', t1.DtCriacao) end) AS DiasUltimoStreak,
            count(distinct t2.IdProduto) AS qtdeProdutoDistintos


    FROM tb_transacoes AS t1

    LEFT JOIN workspace.tmw_loyalty.transacao_produto AS t2
    ON t1.IdTransacao = t2.idTransacao

    LEFT JOIN workspace.tmw_loyalty.produtos as t3
    ON t2.IdProduto = t3.IdProduto

    GROUP BY ALL
    ORDER BY 2 DESC

),

tb_vida AS (

    SELECT IdCliente,
            max(date_diff('{date}', t1.dtCriacao)) AS diasPrimeiraTransacao,
            count(distinct date(t1.DtCriacao)) AS freqVida,
            sum(t1.QtdePontos) AS saldoDia

    FROM workspace.tmw_loyalty.transacoes AS t1
    WHERE DtCriacao < '{date}'
    GROUP BY ALL

),

tb_join AS (

    SELECT  
            t1.*,
            (qtPontosPositivos - (SELECT avg(qtPontosPositivos) FROM tb_cliente_agg)) / ( SELECT stddev(qtPontosPositivos) FROM tb_cliente_agg) AS zScore,
            t2.pctTransacaoChatMessage,
            t2.pctTransacaoListapresenca,
            t2.pctTransacaoPresencaStreak,
            t2.pctTransacaoResgatarPonei,
            t2.pctTransacaoTrocaPontosStreamElements,
            t2.flStreak,
            t2.DiasUltimoStreak,
            t2.qtdeProdutoDistintos,
            t3.saldoDia,
            t3.diasPrimeiraTransacao,
            t3.freqVida

    FROM tb_cliente_agg AS t1
    LEFT JOIN tb_cliente_produto AS t2
    ON t1.idcliente = t2.idcliente

    LEFT JOIN tb_vida AS t3
    ON t1.idcliente = t3.idcliente

)

SELECT '{date}' AS dtRef,
        *
        
FROM tb_join