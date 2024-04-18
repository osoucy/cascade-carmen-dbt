{{ config(materialized='table') }}

select
    distinct location_id, city, country, region, latitude, longitude
from
    {{ref("slv_carmen_sightings")}}
group by
    1, 2, 3, 4, 5, 6

