
{% set renames = {
  'date_witness': 'witnessed',
  'witness': 'observer',
  'agent': 'field_chap',
  'date_agent': 'reported',
  'city_agent': 'interpol_spot',
  'country': 'nation',
  'city': 'place',
  'latitude': 'lat',
  'longitude': 'long',
  'has_weapon': 'has_weapon',
  'has_hat': 'has_hat',
  'has_jacket': 'has_jacket',
  'behavior': 'state_of_mind',
} %}

{{ create_silver(ref('brz_carmen_sightings_australia'), renames) }}
