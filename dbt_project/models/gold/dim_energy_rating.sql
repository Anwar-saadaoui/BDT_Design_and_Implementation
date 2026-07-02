{{
    config(
        materialized='table',
        schema='gold'
    )
}}

with source as (

    select distinct
        energy_rating

    from {{ ref('silver_listings') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['energy_rating']) }} as energy_rating_key,
        coalesce(energy_rating, 'Unknown')                        as energy_rating,

        -- helpful derived flag for BI filtering
        case
            when energy_rating in ('A', 'B') then 'Efficient'
            when energy_rating in ('C', 'D') then 'Average'
            when energy_rating in ('E', 'F', 'G') then 'Inefficient'
            else 'Unknown'
        end                                                        as efficiency_category

    from source

)

select * from final