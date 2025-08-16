{% macro create_schema_if_not_exists(schema_name) %}
  {% if target.type == 'redshift' %}
    CREATE SCHEMA IF NOT EXISTS {{ schema_name }};
  {% endif %}
{% endmacro %}
