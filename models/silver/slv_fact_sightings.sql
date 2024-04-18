{{ config(materialized='table') }}

select
    id,
    date_witness as date,
    month_witness as month,
    witness,
--    agent,
--    date_agent,
--    city_agent,
--    country,
--    city,
--    latitude,
--    longitude,
    has_weapon,
    has_hat,
    has_jacket,
    behavior,
--    region,
    report_id,
    location_id
from
    {{ref("slv_carmen_sightings")}}

