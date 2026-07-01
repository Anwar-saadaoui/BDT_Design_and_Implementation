-- created_at: 2026-07-01T23:34:29.470523269+00:00
-- finished_at: 2026-07-01T23:34:29.634796229+00:00
-- elapsed: 164ms
-- outcome: success
-- dialect: snowflake
-- node_id: not available
-- query_id: 01c56d66-0001-e26e-0000-0002a02eb321
-- desc: execute adapter call
show terse schemas in database REAL_ESTATE_DB
    limit 10000
/* {"app": "dbt", "connection_name": "", "dbt_version": "2.0.0", "profile_name": "real_estate_pipeline", "target_name": "dev"} */;
-- created_at: 2026-07-01T23:34:29.737738915+00:00
-- finished_at: 2026-07-01T23:34:29.855311506+00:00
-- elapsed: 117ms
-- outcome: success
-- dialect: snowflake
-- node_id: model.real_estate_pipeline.silver_listings
-- query_id: 01c56d66-0001-e26e-0000-0002a02eb325
-- desc: get_relation > list_relations call
SHOW OBJECTS IN SCHEMA "REAL_ESTATE_DB"."SILVER" LIMIT 10000;
-- created_at: 2026-07-01T23:34:29.885529462+00:00
-- finished_at: 2026-07-01T23:34:31.204724892+00:00
-- elapsed: 1.3s
-- outcome: success
-- dialect: snowflake
-- node_id: model.real_estate_pipeline.silver_listings
-- query_id: 01c56d66-0001-e32c-0002-a02e00011036
-- desc: execute adapter call
create or replace transient  table REAL_ESTATE_DB.silver.silver_listings
    
    
    
    
    as (

with source as (

    select * from REAL_ESTATE_DB.BRONZE.RAW_LISTINGS

),

deduplicated as (

    -- keep only the most recent row per listing_id (in case of duplicates)
    select *,
        row_number() over (
            partition by listing_id
            order by LOAD_TIMESTAMP desc
        ) as rn
    from source

),

cleaned as (

    select
        listing_id,

        
    CASE
        WHEN REGEXP_REPLACE(LOWER(TRIM(property_type)), '[^a-z]', '') LIKE '%apart%' THEN 'apartment'
        WHEN REGEXP_REPLACE(LOWER(TRIM(property_type)), '[^a-z]', '') LIKE '%hous%'  THEN 'house'
        WHEN REGEXP_REPLACE(LOWER(TRIM(property_type)), '[^a-z]', '') LIKE '%villa%' THEN 'villa'
        WHEN REGEXP_REPLACE(LOWER(TRIM(property_type)), '[^a-z]', '') LIKE '%studio%' THEN 'studio'
        WHEN REGEXP_REPLACE(LOWER(TRIM(property_type)), '[^a-z]', '') LIKE '%duplex%' THEN 'duplex'
        WHEN REGEXP_REPLACE(LOWER(TRIM(property_type)), '[^a-z]', '') LIKE '%penthouse%' THEN 'penthouse'
        ELSE 'unknown'
    END
          as property_type,

        trim(initcap(country))                               as country,
        trim(initcap(city))                                  as city,
        trim(neighborhood)                                   as neighborhood,

        try_cast(surface_m2 as number(10,2))                 as surface_m2,
        try_cast(num_rooms as int)                            as num_rooms,
        try_cast(num_bathrooms as int)                        as num_bathrooms,
        try_cast(floor as int)                                as floor,
        try_cast(year_built as int)                           as year_built,

        
    TRY_CAST(
        REGEXP_REPLACE(price::STRING, '[^0-9.]', '')
        AS NUMBER(15,2)
    )
                            as price,

        coalesce(
            try_to_date(listing_date, 'YYYY-MM-DD'),
            try_to_date(listing_date, 'DD/MM/YYYY'),
            try_to_date(listing_date, 'MM/DD/YYYY'),
            try_to_date(listing_date, 'DD-MM-YYYY'),
            try_to_date(listing_date, 'YYYY/MM/DD')
        )                                                      as listing_date,

        case
            when lower(trim(condition)) in ('new', 'neuf')                then 'new'
            when lower(trim(condition)) in ('good', 'bon')                then 'good'
            when lower(trim(condition)) in ('renovated', 'renove')        then 'renovated'
            when lower(trim(condition)) in ('old', 'ancien')              then 'old'
            else 'unknown'
        end                                                    as condition,

        case
            when lower(trim(heating_type)) like '%gas%'         then 'gas'
            when lower(trim(heating_type)) like '%electric%'    then 'electric'
            when lower(trim(heating_type)) like '%central%'     then 'central'
            when lower(trim(heating_type)) like '%none%'
              or heating_type is null                           then 'none'
            else 'other'
        end                                                    as heating_type,

        
    CASE
        WHEN LOWER(TRIM(parking)) IN ('yes', 'y', 'true', '1', 'oui') THEN TRUE
        WHEN LOWER(TRIM(parking)) IN ('no', 'n', 'false', '0', 'non') THEN FALSE
        ELSE NULL
    END
                          as has_parking,

        case
            when upper(trim(energy_rating)) in ('A','B','C','D','E','F','G')
                then upper(trim(energy_rating))
            else null
        end                                                    as energy_rating,

        try_cast(LOAD_TIMESTAMP::string as timestamp_ntz)      as load_timestamp

    from deduplicated
    where rn = 1

),

final as (

    select
        *,

        -- derived column: price per m2
        case
            when surface_m2 > 0 then round(price / surface_m2, 2)
            else null
        end                                                    as price_per_m2,

        -- derived column: property age
        case
            when year_built is not null
                then year(current_date()) - year_built
            else null
        end                                                    as property_age

    from cleaned

    where
        -- outlier filtering: unrealistic prices / impossible surfaces
        price between 1000 and 50000000
        and surface_m2 between 5 and 2000
        and (year_built is null or year_built between 1800 and year(current_date()))

)

select * from final
    )

/* {"app": "dbt", "dbt_version": "2.0.0", "node_id": "model.real_estate_pipeline.silver_listings", "profile_name": "real_estate_pipeline", "target_name": "dev"} */;
