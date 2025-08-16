{{ config({}) }}
{{ test_accepted_values(column_name="member_casual", model=get_where_subquery(ref('trips_cleaned')), values=["member","casual"]) }}