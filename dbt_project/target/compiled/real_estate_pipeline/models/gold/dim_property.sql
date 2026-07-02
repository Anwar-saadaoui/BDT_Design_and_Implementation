

with source as (

    select distinct
        property_type,
        condition,
        heating_type,
        has_parking

    from REAL_ESTATE_DB.silver.silver_listings

),

final as (

    select
        md5(cast(coalesce(cast(property_type as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(condition as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(heating_type as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(has_parking as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as property_key,
        property_type,
        condition,
        heating_type,
        has_parking

    from source

)

select * from final