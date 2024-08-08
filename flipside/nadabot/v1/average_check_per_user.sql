-- average check per user https://flipsidecrypto.xyz/wownorth/q/yTyrbh25qLTF/average-checks-per-user and https://flipsidecrypto.xyz/wownorth/plotlock-plotlock-A36Irq
WITH txns as 
(select  distinct tx_hash, transaction_fee as tx_fee
 from near.core.fact_transactions b 
where (tx_receiver = 'v1.nadabot.near'
  or   tx_signer = 'v1.nadabot.near'
  and tx_succeeded = TRUE))
,
qmain as (
select  block_timestamp,
        ARGS,
        b.tx_hash,
        signer_id,
        ACTION_NAME,
        receiver_id,
        method_name,
        --args,
        deposit  / 1e24 as deposit
 from near.core.fact_actions_events_function_call b, txns
where b.tx_hash = txns.tx_hash
),

main as (
SELECT
    block_timestamp,
    signer_id,
    receiver_id,
    method_name,
    deposit,
    SPLIT_PART(PARSE_JSON(ARGS):provider_id, ':', 1) AS contract_address,
    SPLIT_PART(PARSE_JSON(ARGS):provider_id, ':', 2) AS check_type
from qmain),

check_type_table as (
select distinct check_type
from main
where check_type != 'has_complete_profile_check'),

avg_count as (
select signer_id, count(check_type) as checks_count
from main
where check_type in (select check_type from check_type_table) and method_name = 'verify_stamp_callback'
group by signer_id
)

select avg(checks_count) from avg_count
