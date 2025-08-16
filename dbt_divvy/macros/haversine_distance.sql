{% macro haversine_distance(lat1, lon1, lat2, lon2) %}
  -- Calculate haversine distance between two coordinates in kilometers
  (
    6371 * acos(
      cos(radians({{ lat1 }})) * 
      cos(radians({{ lat2 }})) * 
      cos(radians({{ lon2 }}) - radians({{ lon1 }})) + 
      sin(radians({{ lat1 }})) * 
      sin(radians({{ lat2 }}))
    )
  )
{% endmacro %}
