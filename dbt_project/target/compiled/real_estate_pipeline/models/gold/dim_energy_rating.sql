

with source as (

    select distinct
        energy_rating

    from REAL_ESTATE_DB.silver.silver_listings

),

final as (

    select
        md5(cast(coalesce(cast(energy_rating as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as energy_rating_key,
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