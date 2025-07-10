#find the total number of products sold each store along with the store name.

SELECT 
    stores.store_name, SUM(order_items.quantity) AS product_sold
FROM
    stores
        JOIN
    orders ON stores.store_id = orders.store_id
        JOIN
    order_items ON order_items.order_id = orders.order_id
GROUP BY stores.store_name;

#Calculate the cumulative sum of Quntities sold for each product over Time . 

WITH q as(select order_items.quantity, products.product_name , orders.order_date
FROM order_items 
JOIN 
   orders
   on order_items.order_id =orders.order_id
JOIN 
    products
ON products.product_id = order_items.product_id)

SELECT*, sum(quantity) over (partition by product_name order by order_date) Cumulative_Quantity
FROM q;

#FIND THE PRODUCT WITH HIGHEST TOTAL SALES (QUANTITY*PRICE) FOR EACH CATEGORY. 
 
with q as (select  categories.category_name,product_name ,sum(order_items.quantity*order_items.list_price) as sales
from categories join products
on categories.category_id = products.category_id
JOIN order_items
ON order_items.product_id = products.product_id
group by categories.category_name,
products.product_name)

 select * from
 (select *, dense_rank() over(partition by category_name order by sales desc) as rnk from q ) as b 
 where rnk =1;

# FIND THE CUSTOMER WHO SPENT THE MOST MONEY ON ORDER . 

select customers.customer_id, 
concat(customers.first_name, " " ,customers.last_name) full_name,
sum(order_items.quantity*order_items.list_price) sales
from customers 
join orders
on customers.customer_id = orders.customer_id
join order_items
on order_items.order_id = orders.order_id
group by 1,2
order by sales desc
limit 1;

#FIND THE HIGHEST PRICED PRODUCT FOR EACH CATEGORY NAMES. 

select * from 
(select products.product_name , products.list_price , categories.category_name,
dense_rank() over(partition by categories.category_name order by products.list_price desc) as rnk
from products 
join categories
on products.category_id = categories.category_id) e
where rnk = 1;

#FIND THE TOTOAL NUMBERS OF ORDERS PLACED BY EACH CUSTOMER PER STORE. 

select customers.customer_id,concat(customers.first_name," " ,customers.last_name) full_name,
stores.store_name,count(orders.order_id) 
from customers join orders
on customers.customer_id = orders.customer_id
join stores
on stores.store_id = orders.store_id
group by customers.customer_id, full_name,
stores.store_name;

#FIND THE NAMES OF STAFF MEMBERS WHO HAVE NOT NOT MADE ANY SALES . 

with a as(select concat(staffs.first_name," " ,staffs.last_name) full_name,
count(orders.order_id) as count 
from staffs Left join orders
on staffs.staff_id = orders.staff_id
group by full_name)

select * from a where count = 0;

#FIND THE TOP 3 MOST SOLD PRODUCT IN TERMS OF QUNTITY. 

select products.product_id,products.product_name ,
 sum(order_items.quantity) most_quntity
from products 
join order_items
on products.product_id = order_items.product_id
group by products.product_name , products.product_id
order by most_quntity desc
limit 3;

#FIND THE MEDIAN VALUE OF THE LIST PRICE . 

with a as(select list_price , row_number() over(order by list_price) rownumber, 
count(*) over() n from products)
 
 select case 
 when mod(n,2) = 0 then (select avg(list_price) from a where rownumber in ((n/2), (n/2)+1))
 else (select list_price from a where rownumber = ((n+1)/2))
 end as median
 from a ;
 
 #LIST ALL PTODUCTS THAT NEVER BEEN ORDERED. (USE EXISTS)
 
select products.product_name 
from products
where not exists(select products.product_id from order_items
where order_items.product_id = products.product_id);

#LIST THE  NAMES OF STAFF MEMBERS WHO HAVE MADE MORE SALES THAN THE AVERAGE NUMBER
#OF SALES BY ALL STAFF MEMBERS .

with a as (select staffs.staff_id , staffs.first_name , 
coalesce(sum(order_items.quantity*order_items.list_price),0) as sales
from staffs 
left join orders
on staffs.staff_id = orders.staff_id
left join order_items
on order_items.order_id = order_items.order_id
group by staffs.staff_id , staffs.first_name) 

select * from a where sales > (select avg(sales) from a);

# IDENTIFY THE CUSTOMER WHO HAVE ORDERD ALL TYPES OF PRODUCTS (i.e., FROM EVERY CATEGORY)

select customers.customer_id , customers.first_name,
count(order_items.product_id) total_orders
from customers
join orders
on customers.customer_id = orders.customer_id
join order_items
on order_items.order_id = orders.order_id
join products
on products.product_id = order_items.product_id
group by customers.customer_id , customers.first_name
having count(distinct products.category_id) = (select count(*) from categories);
