
  
    



create or replace transient  table REAL_ESTATE_DB.gold.dim_location
    
    
    
    
    as (

with source as (

    select distinct
        country,
        city,
        neighborhood

    from REAL_ESTATE_DB.silver.silver_listings

),

final as (

    select
        md5(cast(coalesce(cast(country as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(city as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(neighborhood as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as location_key,
        country,
        city,
        neighborhood

    from source

)

select * from final
    )
;



  