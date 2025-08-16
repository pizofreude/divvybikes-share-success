{% macro get_season(month_col) %}
  CASE 
    WHEN {{ month_col }} IN (12, 1, 2) THEN 'Winter'
    WHEN {{ month_col }} IN (3, 4, 5) THEN 'Spring'
    WHEN {{ month_col }} IN (6, 7, 8) THEN 'Summer'
    WHEN {{ month_col }} IN (9, 10, 11) THEN 'Fall'
    ELSE 'Unknown'
  END
{% endmacro %}
