-- 2.Write a query to create route_details table using suitable data types for the fields, such as route_id, flight_num, origin_airport, destination_airport, aircraft_id, and distance_miles. Implement the 
-- check constraint for the flight number and unique constraint for the route_id fields. Also, make sure that the distance miles field is greater than 0*

create table if not exists routes(
  route_id int not null unique primary key,
  flight_num int constraint chk_1 check (flight_num is not null),
  origin_airport char(3) not null,
  destination_airport char(3) not null,
  aircraft_id varchar(10) not null,
  distance_miles int not null constraint check_2 check (distance_miles > 0) 
);
describe routes;

-- 3. Displaying passengers who have travelled in routes 01 to 25. Take data  from the passengers_on_flights table.

SELECT * FROM passengers_on_flights
where route_id between 01 and 25
order by customer_id;

-- 4.Identifying the number of passengers and total revenue generated in each class of airline and finding total revenue generated so far.

SELECT  class_id, count(*) as total_passenger,sum(no_of_tickets * price_per_ticket) as revenue FROM ticket_details
group by class_id with rollup
order by revenue;

-- 5. Finding the  full name of the customer by extracting the first name and last name from the customer table.

select concat(first_name, ' ' ,last_name) as full_name from customer
order by full_name;

-- 6. query to extract the customers who have registered and booked a ticket. Use data from the customer and ticket_details tables.

select c.customer_id, concat(c.first_name,' ', c.last_name) as name, count(t.no_of_tickets) as total_ticket from customer as c
join ticket_details as t using (customer_id)
group by c.customer_id,name
order by total_ticket desc;

-- 7.Checking details of customers who have booked tickets in Emirates airline

select c.customer_id, concat(c.first_name, ' ' ,c.last_name) as name, t.brand from customer as c
join ticket_details as t using (customer_id)
where brand = 'emirates'
order by c.customer_id;

-- 8. Query to identity the customers who have travelled by Economy Plus class using Group By and Having clause on the passenger_on_flight  table*/
SELECT COUNT(customer_id) AS Total_Customers 
FROM passengers_on_flights 
GROUP BY class_id 
HAVING class_id="Economy Plus";

-- 9. Fetching query to identify whether the revenue has crossed 10000 using the IF clause on the ticket_details table.

Select if (sum(no_of_tickets * price_per_ticket)>10000, 'Revenue crossed 10000' , 'Revenue less than 10000') as Revenue 
from ticket_details;

-- 10. Query to create and grant access to a new user to perform operations on a database

create user 'Ad'@'localhost' identified by 'password';
grant all on *.* to 'Ad'@'localhost' with grant option;

-- 11.Fetching max ticket price for each class

with cte as (
select class_id, max(price_per_ticket) as Maximum_price, 
dense_rank () over (partition by class_id) as dense
from ticket_details
group by class_id)
select class_id, Maximum_price from cte where dense = 1;

 -- 12.query to extract the passengers whose route ID is 4 by improving the speed and performance of the passengers_on_flights table.
 
Select customer_id,route_id from passengers_on_flights where route_id=4;

-- 13.For the route ID 4, write a query to view the execution plan of the passengers_on_flights table

explain select * from pof where route_id =4;

-- 14.query to calculate the total price of all tickets booked by a customer across different aircraft IDs using rollup function

select customer_id, aircraft_id, sum(no_of_tickets * price_per_ticket) as total_sales from ticket_details
group by customer_id, aircraft_id with rollup
order by customer_id;

      
-- 15. query to create a view with only business class customers along with the brand of airlines

CREATE VIEW Bussiness_Class AS
SELECT customer_id,brand, class_id FROM ticket_details WHERE class_id='Bussiness';
SELECT * FROM Bussiness_Class;

-- 16. Write a query to create a stored procedure to get the details of all passengers flying between a range of routes defined in run time. Also, return an error message if the table doesn't exist. */

select * from customer where customer_id in (select distinct customer_id from passengers_on_flights where route_id in (1,5));
DROP PROCEDURE `project`.`check_route`;


-- 17.Write a query to create a stored procedure that extracts all the details from the routes table where the travelled distance is more than 2000 miles.*

DROP PROCEDURE `project`.`check_dist`;
delimiter //
create procedure check_dist()
begin
  select * from routes where distance_miles > 2000;
end //
delimiter ;
call check_dist;

-- 18. Write a query to create a stored procedure that groups the distance travelled by each flight into three categories. The categories are, short distance travel (SDT) for >=0 AND <= 2000 miles, 
-- intermediate distance travel (IDT) for >2000 AND <=6500, and long-distance travel (LDT) for >6500.

select flight_num, distance_miles, case
                            when distance_miles between 0 and 2000 then "SDT"
                            when distance_miles between 2001 and 6500 then "IDT"
                            else "LDT"
					end distance_category from routes;
                    
 
delimiter //
create function group_dist(dist int)
returns varchar(10)
deterministic
begin
  declare dist_cat char(3);
  if dist between 0 and 2000 then
     set dist_cat ='SDT';
  elseif dist between 2001 and 6500 then
    set dist_cat ='IDT';
  elseif dist > 6500 then
   set dist_cat ='LDT';
 end if;
 return(dist_cat);
end //
create procedure group_dist_proc()
begin
   select flight_num, distance_miles, group_dist(distance_miles) as distance_category from routes;
end //
delimiter ;
call group_dist_proc();

-- 19.Write a query to extract ticket purchase date, customer ID, class ID and specify if the complimentary services are provided for the specific class using a stored function in stored 
-- procedure on the ticket_details table. Condition: If the class is Business and Economy Plus, then complimentary services are given as Yes, else it is No*/

select p_date,customer_id, class_id, case
                                 when class_id in ('Bussiness','Economy Plus') then "Yes"
                                 else "No"
						   end as complimentary_service from ticket_details;
delimiter //
create function check_comp_serv(cls varchar(15))
returns char(3)
deterministic
begin
    declare comp_ser char(3);
    if cls in ('Bussiness', 'Economy Plus') then
        set comp_ser = 'Yes';
	else 
	   set comp_ser ='No';
	end if;
    return(comp_ser);
end //

create procedure check_comp_serv_proc()
begin
   select p_date,customer_id,class_id,check_comp_serv(class_id) as complimentary_service from ticket_details;
end //
delimiter ;
call check_comp_serv_proc();


-- 20.Write a query to extract the first record of the customer whose last name ends with Scott using a cursor from the customer table.*/

DROP PROCEDURE `project`.`cust_lname_scott`;
select * from customer where last_name ='Scott' limit 1;
delimiter //
create procedure cust_lname_scott()
begin
   declare c_id int;
   declare f_name varchar(20);
   declare l_name varchar(20);
   declare dob date;
   declare gen char(1);
   
   declare cust_rec cursor
   for
   select * from customer where last_name = 'Scott';
   create table if not exists cursor_table(
										c_id int,
										f_name varchar(20),
										l_name varchar(20),
										dob date,
										gen char(1)
									);
   open cust_rec;
   fetch cust_rec into c_id, f_name, l_name, dob, gen ;
   insert into cursor_table(c_id, f_name, l_name, dob, gen) values(c_id, f_name, l_name, dob, gen);
   close cust_rec;
   select * from cursor_table;
end //
delimiter ;
call cust_lname_scott();




















