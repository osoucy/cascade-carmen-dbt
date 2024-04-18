{{ config(materialized='view') }}

select
    month,
    region,
    count(id)
from (
    select
        *
    from
        {{ref("slv_fact_sightings")}} as f
    join
        {{ref("slv_dim_locations")}} as d
    on f.location_id = d.location_id
)
group by
    month, region
order by
    month desc, count desc
