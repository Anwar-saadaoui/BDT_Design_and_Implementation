{% macro clean_price(column_name) %}
    TRY_CAST(
        REGEXP_REPLACE({{ column_name }}::STRING, '[^0-9.]', '')
        AS NUMBER(15,2)
    )
{% endmacro %}