
{% set renames = {
  'date_witness': 'sighting',
  'witness': 'citizen',
  'agent': 'officer',
  'date_agent': '报道',
  'city_agent': 'city_interpol',
  'country': 'nation',
  'city': 'city',
  'latitude': '纬度',
  'longitude': '经度',
  'has_weapon': 'has_weapon',
  'has_hat': 'has_hat',
  'has_jacket': 'has_jacket',
  'behavior': 'behavior',
} %}

{{ create_silver(ref('brz_carmen_sightings_asia'), renames) }}
