{{
    config(
        materialized='table',
        schema='gold'
    )
}}

with source as (

    select distinct
        country,
        city,
        neighborhood

    from {{ ref('silver_listings') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['country', 'city', 'neighborhood']) }} as location_key,
        country,
        city,
        neighborhood

    from source

)

select * from final