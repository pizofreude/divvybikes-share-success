
    
    

select
    ride_id as unique_field,
    count(*) as n_records

from "divvy"."divvy_bronze"."divvy_trips"
where ride_id is not null
group by ride_id
having count(*) > 1


