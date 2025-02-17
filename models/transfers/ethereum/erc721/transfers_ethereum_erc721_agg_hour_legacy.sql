{{ config(
	tags=['legacy'],
    alias = alias('erc721_agg_hour', legacy_model=True),
    file_format ='delta',
    unique_key='unique_transfer_id'
    )
}}

select
    'ethereum' as blockchain,
    date_trunc('hour', evt_block_time) as hour,
    wallet_address,
    token_address,
    tokenId,
    wallet_address || '-' || date_trunc('hour', evt_block_time) || '-' || token_address || '-'  || tokenId as unique_transfer_id,
    SUM(amount) as amount
from {{ ref('transfers_ethereum_erc721_legacy') }}
group by 1,2,3,4,5,6
-- having sum(amount) = 1 -- commenting this out as it seems to affect the rolling models 
