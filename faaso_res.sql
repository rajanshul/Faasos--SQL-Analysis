#Q1 How many rolls  were ordered?
select count(roll_id) from customer_orders;

#Q2 how many unique customer orders were made 
select count(distinct customer_id) from customer_orders;



#Q3 how many successful orders were deleverd by each drivers
 select driver_id,count(distinct order_id) from driver_order
 where cancellation not in ('Cancellation','Customer Cancellation')
 group by driver_id ;
 
 
 
 #How many of each type of roll was delivered?
 select roll_id,count(roll_id) from 
 customer_orders where roll_id in (
 select order_id from
 (select * , case
 when cancellation in ('Cancellation','Customer Cancellation') then 'c' else 'nc' end as order_cancel_details from driver_order
 ) a
 where order_cancel_details = 'nc')
 group by roll_id
 ;
 
 # how mny veg and nonveg rolls were orders by each customers
 

 select  a.*,b.roll_name from
 (
 select customer_id, roll_id,count(roll_id) cnt 
 from customer_orders
 group by  customer_id,roll_id)a inner join rolls b on a.roll_id=b.roll_id;
 
 
 # what was the maximun number of rolls delivered in a single order ?
 
 select order_id, count(roll_id) cnt from  customer_orders where order_id in (
 select order_id from
 (select * , case
 when cancellation in ('Cancellation','Customer Cancellation') then 'c'
 else 'nc' end as order_cancel_details from driver_order
 ) a
 where order_cancel_details = 'nc')
 group by order_id
 order by cnt desc limit 0,1;
 

# what is the avrage time in min it took  for each driver t arive at the fasoos  hq to pickup the order 
select * from driver_order;
select * from customer_orders;

select driver_id,sum(diff)/count(order_id) abg_mins from
(select * from
(select *,row_number() over(partition by order_id order by diff)rnk from 
(select * ,
DATEDIFF(minute, b.pickup_time, a.order_date) AS diff
from 
customer_orders a inner join 
driver_order b on a.order_id= b.order_id
where b.pickup_time is not null)a)b where rnk=1)
group by driver_id;


#is there any relasion ship between the no of rolls and log the order take to prepare

select order_id,count(roll_id), sum(diff)/count(roll_id) from
(select  a.order_id,a.customer_id,a.roll_id,a.not_include_items,a.extra_items_included,a.order_date,b.driver_id,b.pickup_time,b.distance,b.duration,b.cancellation,
DATEDIFF(minute, b.pickup_time, a.order_date) AS diff
from 
customer_orders a inner join 
driver_order b on a.order_id= b.order_id
where b.pickup_time is not null) a
 group by order_id;
 
 
 
 # what is the average distance  travelled for each customer
 select customer_id,sum(distance)/count(order_id)from
(select  a.order_id,a.customer_id,a.roll_id,a.not_include_items,a.extra_items_included,a.order_date,
b.driver_id,b.pickup_time,b.distance,b.duration,b.cancellation from 
customer_orders a inner join 
driver_order b on a.order_id= b.order_id
where b.pickup_time is not null) a
group by customer_id;

 select customer_id,sum(distance)/count(order_id) from
(select* from 
customer_orders a inner join 
driver_order b on a.order_id= b.order_id
where b.pickup_time is not null)a
group by customer_id;


# For each custommer, how many delivered rolls had at least 1 change and many how many had no change

with  tmp_customer_order(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) as
(

select order_id,customer_id,roll_id, 
case when not_include_items='' or not_include_items is null then '0' else not_include_items end  as new_not_include_items ,
case when extra_items_included is null or extra_items_included='' or extra_items_included= 'NaN' or extra_items_included= 'NULL' then '0' else extra_items_included end  as new_extra_items_included
,order_date from customer_orders
)




,temp_driver_order(order_id,driver_id,pickup_time,distance,duration,new_Cancellation) as
(
select order_id,driver_id,pickup_time,distance,duration,
case when cancellation in ('cancellation','Customer Cancellation') then 0 else 1 end as new_Cancellation
from driver_order     
)

select customer_id, chg_no_chg,count(order_id) from
(
select *,case 
when not_include_items ='0' and extra_items_included='0' then 'no-change' else 'change' end as chg_no_chg
from tmp_customer_order where order_id in(
select order_id  from temp_driver_order where new_Cancellation!= 0))a 
group by customer_id, chg_no_chg ;


# how Many rols were delivered that had both exclusion and extras

with  tmp_customer_order(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date) as
(
select order_id,customer_id,roll_id, 
case when not_include_items='' or not_include_items is null then '0' else not_include_items end  as new_not_include_items ,
case when extra_items_included is null or extra_items_included='' or extra_items_included= 'NaN' or extra_items_included= 'NULL' then '0' else extra_items_included end  as new_extra_items_included
,order_date from customer_orders
)
,temp_driver_order(order_id,driver_id,pickup_time,distance,duration,new_Cancellation) as
(
select order_id,driver_id,pickup_time,distance,duration,
case when cancellation in ('cancellation','Customer Cancellation') then 0 else 1 end as new_Cancellation
from driver_order     
)

select chg_no_chg, count(chg_no_chg) from
(select *,
case 
when not_include_items !='0' and extra_items_included !='0' then 'both inc exc' else 'ether 1 in or exc' end as chg_no_chg
from tmp_customer_order where order_id in(
select order_id  from temp_driver_order where new_Cancellation!= 0))a
group by chg_no_chg;


# whatis the diff bitween longest and showest delevary time

 select max(duration) ,- min(duration)as diff from(
 cast(case when duration like '%min%' then left(duration ,charindex('m',duration)-1) else duration end as integer) as duration
 from driver_order 
 where duration is not null)a;
 
 # what was the average speed for each driver for delivery and do you notice any trend for these values?
 
 select order_id,driver_id,distance/duration speed from
( select order_id,driver_id,(trim(replace(lower(distance),'Km','')) as decimal(4,2)) distance,
 cast(case when duration like '%min%' then left(duration ,charindex('m',duration)-1) else duration end as int) as duration
 from driver_order where distance is not null) a;
 
 
 # What is the Sucessesful delivary persentage for each driver?
 
 select driver_id ,s/c cancelled_per from
 (select driver_id, sum(can_per) s, count(driver_id) c from
 (select driver_id ,
 case
 when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as can_per 
  from driver_order) a
  group by driver_id)b ;
 



 
 