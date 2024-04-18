# Cascade Data Engineering Assessment

## Background 
The objective of this assessment is to showcase our ability to:
- Design and build a basic ELT pipeline, moving and processing raw data into aggregated, 
  analytics-ready datasets.
- Showcase our ability to use modern tooling to efficiently generate the desired results
- Have fun!

## Problem Definition
We are presented with an Excel spreadsheet storing sightings of Carmen Sandiego
and are asked to answer a few questions with respect to this dataset. 

<img src="images/carmen.jpeg" alt="carmen" width="200"/>

## Proposed Solution
In this version of the assignment, the solution leverages a dbt project linked
to a local instance of PostgreSQL database. It organizes the tables and views 
following medallion architecture.

An alternative, spark-based approach leveraing Databricks DLT and Laktory was
also provided [here](https://github.com/osoucy/cascade-carmen-spark).

## Medallion
The problem to be solved is an excellent candidate for a medallion 
architecture, consisting of 3 layers:

* Bronze tables: raw and unaltered data 
* Silver tables: filtered, cleaned and modeled data
* Gold tables: aggregated data, ready for analytics consumption and specific use cases

### Bronze Tables
The bronze tables are an exact representation of the data found in the Excel
spreadsheets. There is one table per region (or per sheet) using the following
naming convention: `brz_carmen_sigthings_{region}`. As an example, here is the
bronze table for asia: 
![brz-asia](./images/brz_asia.png)

The column names have not been altered in any way and no transformation have 
been applied. The tables are created from csv using dbt seed function.

The csv files were generated from a python [script](scripts/build_seeds.py)
using pandas reader and writer:
```py
import pandas as pd

REGIONS = ["africa", "america", "asia", "atlantic", "australia", "europe",
    "indian", "pacific"]

for region in REGIONS:

    # Read
    df = pd.read_excel("../data/carmen_sightings_20220629061307.xlsx", sheet_name=region.upper())
    df["region"] = region

    # Write
    df.to_csv(f"../seeds/brz_carmen_sightings_{region}.csv", index=False)
```

### Silver Tables
The next step is to define the silver as a transformation of the bronze tables.
The transformation in this case consisted of :
* Standardize column names
* Selecting column of interest
* Creating normalization ids

A preliminary analysis of the raw data has shown that no duplicates were found
in any of the regions. Here is what it looks like for the Asia region.
![slv-asia](./images/slv_asia.png)

We used a dbt [macro](macros/create_silver.sql) to apply the same 
transformation to all regions.
```sql
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
```

The `renames` dictionary is region-specific and maps the region-specific column
names to the standard column names. Columns `location_id` and `report_id` will
be used for normalization of the data model.

Once we have all the region-specific silver tables, we create 
`slv_carmen_sightings` which is a union of all other silver tables.

```sql
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
```


#### Normalization

To reduce redundancy and better organize the data for analytics, the wide
table is transformed in 3 tables:
- 1 fact table `slv_fact_sightings` listing all sightings
- 1 fact table `slv_fact_reports` listing all reports (agent, date city)
- 1 dimension `slv_dim_locations` table providing the details of a location (city, country, region, latitude and longitude)

The relationships are summarized in this entity relationships diagram:
![erd](./images/erd.png)


### Gold Tables
Finally, 3 gold tables (and a view) were defined to the analytics questions.

#### Behavior Aggregation
The first gold table `gld_sightings_by_behavior` counts the number of occurrence
of each behavior. It is defined as
```sql
 select
    behavior,
    count(id) as count
from
    {{ref("slv_carmen_sightings")}}
group by
    behavior
order by
    count desc
```

and results in
![gld-behaviour](./images/gld_behavior.png)

#### Monthly aggregation
The second table `gld_carmen_sightings_by_month` is the monthly aggregation defined as:

```yaml
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
```

This one is a bit more involving as it:

* Create a new column `has_target_behavior` that is `1` when the behavior is in the top 3 identified previously
* Create a new column `has_target_outfit` that is `1` when the outfit (armed, hat, jacket) matches the description provided in the assessment
* Group all rows of a month and 
  * Count the total number of rows for each month
  * Count the match for target behavior
  * Count the match for target outfit
* Calculate the probability of seeing target behavior `target_behavior_probability`
* Calculate the probability of seeing target outfit `target_outfit_probability`

And the final result is:
![gld-month](./images/gld_month.png)


#### Monthly and Regional Aggregation
To identify the region most frequently visited by Carmen each month, we proceed
in two steps:
* Create a view `gld_sightings_by_month_region` that counts the number of sightings per region per month
* Create a view `gld_most_visited_regions` on top of that view that keeps only the row associated with the region with most occurrence for each month

There are defined as:
```sql
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
```

and

```sql
select
    distinct on (month) month, region, count
from
    {{ref("gld_sightings_by_month_region")}}
order by
    month desc, count desc
```

And the result is:
![gld-most-visited](./images/gld_most_visited.png)

### Data Lineage
As an added bonus, dbt builds a data lineage graphs that helps understand
the relationship between the different tables.

![gld-lineage](./images/lineage.png)


# Analytics

## a) In which region is Carmen most likely to be found each month?
The answer is provided in column `region` of table `gld_most_visited_regions`. 
Here are the 6 most recent results:

| month   | region  |
|---------|---------|
| 2022-06 | america |
| 2022-05 | asia    |
| 2022-04 | america |
| 2022-03 | europe  |
| 2022-02 | america |
| 2022-01 | america |


## b) What is the monthly probability for Carmen to be armed and wearing a jacket, but not a hat?
The answer is provided in column `target_outfit_probability` of table `gld_sightings_by_month`. 
Here are the 6 most recent results:

| month   | probability |
|---------|-------------|
| 2022-06 | 3.448%      |
| 2022-05 | 3.226%      |
| 2022-04 | 3.333%      |
| 2022-03 | 6.452%      |
| 2022-02 | 3.571%      |
| 2022-01 | 0.000%      |

Overall, the probability of Carmen to be armed, wearing a jacket, but no hat
are very low with 3.91% on average. The only general observation that can be
drawn from this is that this specific combination is very rare. Further 
investigation would be required to identify if:
* One of the contributing factor is low in itself (she could be armed on very rare occasions for example)
* She tends to wear a hat when she is armed
* We have a situation of survivorship bias where wearing a jacket means being able to better conceal the weapon and hiding it from the agent.

## c) What are the most frequent behaviors of Carmen Sandiego?
The answer is provided in column `count` of table `gld_carmen_sightings_by_behavior`. 
Here are the 3 most frequent results:
* out-of-control
* complaining
* happy

## d) What is the monthly probability for Carmen to show one of the top 3 behavior? 
The answer is provided in column `target_behavior_probability` of table `gld_carmen_sightings_by_month`. 
Here are the 6 most recent results:

| month   | probability |
|---------|-------------|
| 2022-06 | 24.14%      |
| 2022-05 | 22.58%      |
| 2022-04 | 20.00%      |
| 2022-03 | 16.13%      |
| 2022-02 | 10.71%      |
| 2022-01 | 12.90%      |
