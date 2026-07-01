{% macro clean_property_type(column_name) %}
    CASE
        WHEN REGEXP_REPLACE(LOWER(TRIM({{ column_name }})), '[^a-z]', '') LIKE '%apart%' THEN 'apartment'
        WHEN REGEXP_REPLACE(LOWER(TRIM({{ column_name }})), '[^a-z]', '') LIKE '%hous%'  THEN 'house'
        WHEN REGEXP_REPLACE(LOWER(TRIM({{ column_name }})), '[^a-z]', '') LIKE '%villa%' THEN 'villa'
        WHEN REGEXP_REPLACE(LOWER(TRIM({{ column_name }})), '[^a-z]', '') LIKE '%studio%' THEN 'studio'
        WHEN REGEXP_REPLACE(LOWER(TRIM({{ column_name }})), '[^a-z]', '') LIKE '%duplex%' THEN 'duplex'
        WHEN REGEXP_REPLACE(LOWER(TRIM({{ column_name }})), '[^a-z]', '') LIKE '%penthouse%' THEN 'penthouse'
        ELSE 'unknown'
    END
{% endmacro %}