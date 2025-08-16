
    
    

select
    station_id as unique_field,
    count(*) as n_records

from "divvy"."public_silver"."stations_cleaned"
where station_id is not null
group by station_id
having count(*) > 1


