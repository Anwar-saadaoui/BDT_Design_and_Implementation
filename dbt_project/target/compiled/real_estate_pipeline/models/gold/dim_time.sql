

with source as (

    select distinct
        listing_date

    from REAL_ESTATE_DB.silver.silver_listings
    where listing_date is not null

),

final as (

    select
        md5(cast(coalesce(cast(listing_date as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))  as time_key,
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