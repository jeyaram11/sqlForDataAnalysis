--DDL = Data Defination language (blueprints) create, alter, drop 
--DML = Data manipulation language, to query the actual data, insert, update, select 
--over function 
SELECT 
	booking_id, 
	listing_name,
	neighbourhood_group,
	price,
	price / AVG(price) over(),
	price / AVG(price) over() -1 ,
	(price / AVG(price) over() - 1) * 100
FROM bookings;

--partition function 
--partitioning by neighbourhood group 
SELECT
	booking_id, 
	listing_name,
	neighbourhood_group,
	neighbourhood,
	price, 
	AVG(price) over(partition by neighbourhood_group) as avg_price_by_neigh_group
FROM bookings;

--partition function 
--partitioning by neighbourhood group and neighbourhood  
SELECT
	booking_id, 
	listing_name,
	neighbourhood_group,
	neighbourhood,
	price, 
	AVG(price) over(partition by neighbourhood_group) as avg_price_by_neigh_group,
	AVG(price) over(partition by neighbourhood_group,neighbourhood) as avg_price_by_neigh_group_and_neigh
FROM bookings;

--row_number when values are same it will assign a number and move on 
--rank will give the same ranking but will continute from where you left e.g. 1,1,1,4
--dense_rank will give the same ranking but will not coninute the count from where you left e.g. 1,1,1,2
SELECT
	booking_id, 
	listing_name,
	neighbourhood_group,
	neighbourhood,
	price, 
    ROW_NUMBER() OVER(order by price desc) as overall_price_rank_using_row_number,
	RANK() over(order by price desc) as overall_price_rank_using_rank,
	DENSE_RANK() over(order by price desc) as overall_price_rank_using_rank,
	ROW_NUMBER() OVER(partition by neighbourhood_group order by price desc) as overall_price_rank_by_neigh_group
FROM bookings;

--lag by 1 period
SELECT 
 	booking_id, 
	listing_name, 
	host_name,
	price,
	last_review,
	lag(price) over(partition by host_name order by last_review)
	FROM bookings;
	
--lag by 2 periods 
SELECT 
 	booking_id, 
	listing_name, 
	host_name,
	price,
	last_review,
	lag(price,2) over(partition by host_name order by last_review)
	FROM bookings;
	
--first value 
--write a query to display the most expenise in the neighbourhood
SELECT 
	booking_id, 
	listing_name,
	neighbourhood_group,
	neighbourhood,
	price,
	first_value(listing_name) 
	over(partition by neighbourhood_group,neighbourhood order by price desc) most_expensive_listing,
	last_value(listing_name) 
	over(partition by neighbourhood_group,neighbourhood order by price desc
		range between unbounded preceding and unbounded following
		) least_expensive_listing
FROM bookings;

--first value 
--last value  alternate function 
select *, 
first_value(listing_name) over w as most_expensive,
last_value(listing_name) over w as least_expensive
FROM bookings 
window w as (partition by neighbourhood_group, neighbourhood order by price desc
			range between unbounded preceding and unbounded following 
			);
			
--nth value 
--fetch a value from any position 
SELECT *, 
NTH_VALUE(listing_name,3) OVER (PARTITION BY neighbourhood_group, neighbourhood order by price desc 
							  range between unbounded preceding and unbounded following 
							 ) third_most_expensive 
FROM bookings;


--NTILE
--Write a query to segregate all the expensive phones, mid range phones and the cheaper phones
SELECT host_name, 
       neighbourhood_group, 
	   neighbourhood, 
	   price,
	   case 
	   	when buckets = 1 then 'expensive'
	    when buckets = 2 then 'Mid Range'
		when buckets = 3 then 'least expensive' end Price_range
		from (
SELECT *, 
	  ntile(3) over(order by price desc) as buckets
FROM bookings 
WHERE neighbourhood_group = 'Manhattan' and 
      neighbourhood = 'Midtown')x

--CUME_DIST (cumulative distrubution):
--quert to fetch all products which are constituting to the first 30%

SELECT * FROM (
SELECT host_name, 
       host_id, 
	   booking_id
       neighbourhood_group, 
	   neighbourhood, 
	   price,
	   round(cume_dist() over(order by price desc)::numeric * 100,2) distribution
FROM bookings
WHERE neighbourhood = 'Upper West Side')x 
where x.distribution <=30


--Percent_rank()
--query to identify how much percentage more expensive a listing is compared to all lisitings
SELECT *,
      round(percent_rank() over(order by price)::numeric * 100,2) percentage_rank  
FROM(
SELECT distinct booking_id, listing_name, price  FROM bookings 
)x



SELECT neighbourhood, sum(price) as total_price
 from bookings 
 group by neighbourhood 
  having sum(price) < 10000
 order by total_price desc

