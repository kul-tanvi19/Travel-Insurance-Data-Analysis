-- Create database
create database insurance

use insurance

-- Import data from csv file

select *
from travel_insurance


-------------------------------------------------------------------------------------
-------------------------------- Feature Engineering --------------------------------
-------------------------------------------------------------------------------------

-- Add column age_group

alter table travel_insurance
add age_group varchar(max) 


update travel_insurance
set age_group = (
	case
		when Age < 10 then '< 10 years'
		when Age between 11 and 20 then '11-20 years'
		when Age between 21 and 30 then '21-30 years'
		when Age between 31 and 40 then '31-40 years'
		when Age between 41 and 50 then '41-50 years'
		when Age between 51 and 60 then '51-60 years'
		when Age between 61 and 70 then '61-70 years'
		when Age between 71 and 80 then '71-80 years'
		when Age between 81 and 90 then '81-90 years'
		when Age between 91 and 100 then '91-100 years'
		else '100+ years'
	end
)

-------------------------------------------------------------------------------------
----------------------------------- Data Cleaning -----------------------------------
-------------------------------------------------------------------------------------
-- Step 1 : Check for null values

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME ='travel_insurance' AND IS_NULLABLE = 'yes';

	--Gender column contains null values


-- % of null values present 

select 
SUM(
	case
		when gender is null then 1
	end) * 100 / COUNT(*) '%_of_nulls'
from travel_insurance
	
		-- Gender column contains 71% null values so we can drop this column


-- Drop gender column

alter table travel_insurance
drop column gender



-------------------------------------------------------------------------------------
---------------------------------------- EDA ----------------------------------------
-------------------------------------------------------------------------------------

-- 1. Total revenue

select concat(round(SUM(net_sales)/1000000,2),' millions') total_revenue
from travel_insurance


-- 2. How many customers insured?

select COUNT(*) total_customers
from travel_insurance


-- 3. Total commision paid

select CONCAT(round(sum(Commision_in_value)/1000,2), ' K') total_commision
from travel_insurance


-- 4. Total claims

select COUNT(*) total_claims
from travel_insurance
where Claim = 'yes'


-- 5. How many unique agencies are there?

select count(distinct(Agency)) agency_count
from travel_insurance


-- 6. What are the different agency types?

select distinct Agency_Type
from travel_insurance


-- 7. Count of customers based on agency type

select agency_type, COUNT(*) total_customers
from travel_insurance
group by Agency_Type


-- 8. Top 10 destinations based on count of customers insured

select top 10 Destination ,COUNT(*) count_of_customers
from travel_insurance
where Claim = 'yes'
group by Destination
order by count_of_customers desc


-- 9. Count of customers insured based on age_group

select age_group, COUNT(*) count_of_customers
from travel_insurance
where Claim = 'yes'
group by age_group
order by count_of_customers desc


-- 10. Total revenue based on agency

select Agency ,round(sum(Net_Sales),2) total_revenue
from travel_insurance
group by Agency
order by total_revenue desc


-- 11. Total commision paid based on agency

select Agency, ROUND(sum(Commision_in_value),2) total_commision
from travel_insurance
group by Agency
order by total_commision desc


-- 12. Count of customers based on product names

select Product_Name, COUNT(*) total_customers
from travel_insurance
group by Product_Name
order by total_customers desc


-- 13. % of age group that raises most of the claims

with cte as(
	select COUNT(*) as cnt
	from travel_insurance
	where Claim = 'yes'
),
cte1 as (
	select distinct age_group,
	cast(SUM(case when Claim = 'yes' then 1 end) over(partition by age_group) as float) total_claims
	from travel_insurance
),
res as (
	select c2.age_group, round(c2.total_claims * 100 / c1.cnt, 2) '%_of_claims'
	from cte c1
	cross join  cte1 c2
)
select *
from res
order by age_group


-- 14. Count of agencies based on distribution channel

select Distribution_Channel, COUNT(*) total_agencies
from travel_insurance
group by Distribution_Channel


-- 15. Count of distribution channnel based on agencies

select Agency, Distribution_Channel ,COUNT(*) count_of_dest_channel
from travel_insurance
group by Agency, Distribution_Channel
order by count_of_dest_channel desc


-- 16. Top 5 online distribution agencies

select top 5 Agency, COUNT(*) cnt
from travel_insurance
where Distribution_Channel = 'online'
group by Agency
order by cnt desc


-- 17. Which product plan is most claimed as per destination?

select res1.Destination, res1.Product_Name, res1.count_of_customers_insured
from (
	select *
	from (
		select distinct Destination, Product_Name, COUNT(*) count_of_customers_insured,
		dense_rank() over(partition by Destination order by COUNT(*) desc) rnk
		from travel_insurance
		where Claim = 'yes'
		group by Destination, Product_Name
	)result
	where result.rnk <= 3
)res1
order by Destination, count_of_customers_insured desc


-- 18. Top 10 highest travel insurance plan sold 

select  top 10 Agency, Product_Name,  COUNT(*) total_plan_sold
from travel_insurance
group by Agency, Product_Name
order by total_plan_sold desc


-- 19. Max and min duration of travel based on insurance plans

select Product_Name, MIN(duration) min_duration, MAX(duration) max_duration
from travel_insurance
group by Product_Name
having  MIN(duration) >= 0 and MAX(duration) >= 0
order by Product_Name