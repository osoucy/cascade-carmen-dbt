{{ config(materialized='view') }}

select
    behavior,
    count(id) as count
from
    {{ref("slv_carmen_sightings")}}
group by
    behavior
order by
    count desc
