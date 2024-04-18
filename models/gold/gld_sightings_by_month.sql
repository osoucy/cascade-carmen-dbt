{{ config(materialized='view') }}

SELECT
    month,
    count(id) as count,
    sum(has_target_behavior::int)  as target_behavior_count,
    sum(has_target_outfit::int)  as target_outfit_count,
    sum(has_target_behavior::int)::float / count(id)  as target_behavior_probability,
    sum(has_target_outfit::int)::float / count(id) as target_outfit_probability
from (
    select
        *,
        behavior IN ('out-of-control', 'complaining', 'happy') as has_target_behavior,
        has_weapon AND has_jacket AND NOT has_hat AS has_target_outfit
    from
        {{ref("slv_fact_sightings")}}
)
group by
    month
order by
    month desc
