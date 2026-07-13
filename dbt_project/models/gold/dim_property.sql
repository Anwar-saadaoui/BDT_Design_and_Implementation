{{
    config(
        materialized='table',
        schema='gold'
    )
}}

with source as (

    select distinct
        property_type,
        condition,
        heating_type,
        has_parking

    from {{ ref('silver_listings') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['property_type', 'condition', 'heating_type', 'has_parking']) }} as property_key,
        property_type,
        condition,
        heating_type,
        has_parking

    from source

)

select * from final