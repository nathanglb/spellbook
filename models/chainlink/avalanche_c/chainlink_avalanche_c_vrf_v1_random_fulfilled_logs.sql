{{
  config(
    tags=['dunesql'],
    alias=alias('vrf_v1_random_fulfilled_logs'),
    materialized='view'
  )
}}

SELECT
  'avalanche_c' as blockchain,
  block_hash,
  contract_address,
  data,
  topic0,
  topic1,
  topic2,
  topic3,
  tx_hash,
  block_number,
  block_time,
  index,
  tx_index,
  tx_from
FROM
  {{ source('avalanche_c', 'logs') }} logs
WHERE
  topic0 = 0xa2e7a402243ebda4a69ceeb3dfb682943b7a9b3ac66d6eefa8db65894009611c -- RandomnessRequestFulfilled