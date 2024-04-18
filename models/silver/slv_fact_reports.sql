{{ config(materialized='table') }}

select
    distinct report_id, agent, date_agent as date, city_agent as city
from
    {{ref("slv_carmen_sightings")}}
group by
    1, 2, 3, 4

