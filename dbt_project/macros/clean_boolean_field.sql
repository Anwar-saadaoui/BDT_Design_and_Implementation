{% macro clean_yes_no(column_name) %}
    CASE
        WHEN LOWER(TRIM({{ column_name }})) IN ('yes', 'y', 'true', '1', 'oui') THEN TRUE
        WHEN LOWER(TRIM({{ column_name }})) IN ('no', 'n', 'false', '0', 'non') THEN FALSE
        ELSE NULL
    END
{% endmacro %}