{{
    config(
        materialized='table',
        schema='gold'
    )
}}

with source as (

    select distinct
        listing_date

    from {{ ref('silver_listings') }}
    where listing_date is not null

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['listing_date']) }}  as time_key,
        listing_date,
        year(listing_date)                                        as year,
        quarter(listing_date)                                     as quarter,
        month(listing_date)                                       as month,
        monthname(listing_date)                                   as month_name,
        day(listing_date)                                         as day,
        dayname(listing_date)                                     as day_name,
        weekofyear(listing_date)                                  as week_of_year

    from source

)

select * from final