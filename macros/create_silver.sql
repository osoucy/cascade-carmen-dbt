{% macro create_silver(source_table, renames) %}
    select
        {{ renames.date_witness }}::date as date_witness,
        {{ renames.witness }}::varchar as witness,
        {{ renames.agent }}::varchar as agent,
        {{ renames.date_agent }}::date as date_agent,
        {{ renames.city_agent }}::varchar as city_agent,
        {{ renames.country }}::varchar as country,
        {{ renames.city }}::varchar as city,
        {{ renames.latitude }}::float as latitude,
        {{ renames.longitude }}::float as longitude,
        {{ renames.has_weapon }}::boolean as has_weapon,
        {{ renames.has_hat }}::boolean as has_hat,
        {{ renames.has_jacket }}::boolean as has_jacket,
        {{ renames.behavior }}::varchar as behavior,
        region::varchar as region,
        date_trunc('month', {{ renames.date_witness }}::date) as month_witness,
        {{ dbt_utils.generate_surrogate_key([renames.city]) }} as location_id,
        {{ dbt_utils.generate_surrogate_key([renames.agent, renames.date_agent, renames.city_agent]) }} as report_id
    from
        {{ source_table }}
{% endmacro %}