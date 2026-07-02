

with listings as (

    select * from REAL_ESTATE_DB.silver.silver_listings

),

dim_property as (
    select * from REAL_ESTATE_DB.gold.dim_property
),

dim_location as (
    select * from REAL_ESTATE_DB.gold.dim_location
),

dim_time as (
    select * from REAL_ESTATE_DB.gold.dim_time
),

dim_energy_rating as (
    select * from REAL_ESTATE_DB.gold.dim_energy_rating
),

final as (

    select
        l.listing_id,

        -- foreign keys
        p.property_key,
        loc.location_key,
        t.time_key,
        e.energy_rating_key,

        -- measures
        l.surface_m2,
        l.num_rooms,
        l.num_bathrooms,
        l.floor,
        l.year_built,
        l.price,
        l.price_per_m2,
        l.property_age,

        l.load_timestamp

    from listings l

    left join dim_property p
        on  coalesce(l.property_type, '')  = coalesce(p.property_type, '')
        and coalesce(l.condition, '')      = coalesce(p.condition, '')
        and coalesce(l.heating_type, '')   = coalesce(p.heating_type, '')
        and coalesce(l.has_parking::string, '') = coalesce(p.has_parking::string, '')

    left join dim_location loc
        on  coalesce(l.country, '')      = coalesce(loc.country, '')
        and coalesce(l.city, '')         = coalesce(loc.city, '')
        and coalesce(l.neighborhood, '') = coalesce(loc.neighborhood, '')

    left join dim_time t
        on l.listing_date = t.listing_date

    left join dim_energy_rating e
        on coalesce(l.energy_rating, 'Unknown') = e.energy_rating

)

select * from final