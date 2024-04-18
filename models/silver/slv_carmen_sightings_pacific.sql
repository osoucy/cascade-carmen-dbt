
{% set renames = {
  'date_witness': 'sight_on',
  'witness': 'sighter',
  'agent': 'filer',
  'date_agent': 'file_on',
  'city_agent': 'report_office',
  'country': 'nation',
  'city': 'town',
  'latitude': 'lat',
  'longitude': 'long',
  'has_weapon': 'has_weapon',
  'has_hat': 'has_hat',
  'has_jacket': 'has_jacket',
  'behavior': 'behavior',
} %}

{{ create_silver(ref('brz_carmen_sightings_pacific'), renames) }}
