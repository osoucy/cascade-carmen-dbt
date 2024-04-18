{{ config(materialized='view') }}

select
    distinct on (month) month, region, count
from
    {{ref("gld_sightings_by_month_region")}}
order by
    month desc, count desc