{{
    config(
        tags=['dunesql'],
        schema = 'sudoswap_ethereum',
        alias = alias('airdrop_claims'),
        materialized = 'incremental',
        file_format = 'delta',
        incremental_strategy = 'merge',
        unique_key = ['recipient', 'tx_hash', 'evt_index'],
        post_hook='{{ expose_spells(\'["ethereum"]\',
                                "project",
                                "sudoswap",
                                \'["hildobby"]\') }}'
    )
}}

{% set sudo_token_address = '0x3446dd70b2d52a6bf4a5a192d9b0a161295ab7f9' %}

WITH early_price AS (
    SELECT MIN(minute) AS minute
    , MIN_BY(price, minute) AS price
    FROM {{ source('prices', 'usd') }}
    WHERE blockchain = 'ethereum'
    AND contract_address= {{sudo_token_address}}
    )

SELECT 'ethereum' AS blockchain
, t.evt_block_time AS block_time
, t.evt_block_number AS block_number
, 'sudoswap' AS project
, 1 AS airdrop_number
, t.account AS recipient
, t.contract_address
, t.evt_tx_hash AS tx_hash
, t.amount AS amount_raw
, CAST(t.amount/POWER(10, 18) AS double) AS amount_original
, CASE WHEN t.evt_block_time >= (SELECT minute FROM early_price) THEN CAST(pu.price*t.amount/POWER(10, 18) AS double)
    ELSE CAST((SELECT price FROM early_price)*t.amount/POWER(10, 18) AS double)
    END AS amount_usd
, {{sudo_token_address}} AS token_address
, 'SUDO' AS token_symbol
, t.evt_index
FROM {{ source('sudoswap_ethereum', 'Astrodrop_evt_Claimed') }} t
LEFT JOIN {{ ref('prices_usd_forward_fill') }} pu ON pu.blockchain = 'ethereum'
    AND pu.contract_address= {{sudo_token_address}}
    AND pu.minute=date_trunc('minute', t.evt_block_time)
    {% if is_incremental() %}
    AND pu.minute >= date_trunc('day', now() - interval '7' Day)
    {% endif %}
{% if is_incremental() %}
WHERE t.evt_block_time >= date_trunc('day', now() - interval '7' Day)
{% endif %}