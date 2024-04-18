{{ config(materialized='table') }}

WITH
 africa AS (SELECT * FROM {{ ref('slv_carmen_sightings_africa') }}),
 america AS (SELECT * FROM {{ ref('slv_carmen_sightings_america') }}),
 asia AS (SELECT * FROM {{ ref('slv_carmen_sightings_asia') }}),
 atlantic AS (SELECT * FROM {{ ref('slv_carmen_sightings_atlantic') }}),
 australia AS (SELECT * FROM {{ ref('slv_carmen_sightings_australia') }}),
 europe AS (SELECT * FROM {{ ref('slv_carmen_sightings_europe') }}),
 indian AS (SELECT * FROM {{ ref('slv_carmen_sightings_indian') }}),
 pacific AS (SELECT * FROM {{ ref('slv_carmen_sightings_pacific') }})

SELECT
    {{ dbt_utils.generate_surrogate_key(['date_witness', 'location_id', 'report_id']) }} as id,
    *
FROM
    (
        SELECT * FROM africa
        UNION
        SELECT * FROM america
        UNION
        SELECT * FROM asia
        UNION
        SELECT * FROM atlantic
        UNION
        SELECT * FROM australia
        UNION
        SELECT * FROM europe
        UNION
        SELECT * FROM indian
        UNION
        SELECT * FROM pacific
    )
