CREATE SCHEMA `resturent`;

CREATE TABLE `resturent`.`sales`(
customer_id VARCHAR (1),
order_date DATE,
product_id INTEGER
);

INSERT INTO `resturent`.`sales`
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE `resturent`.`menu` (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO `resturent`.`menu`
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE `resturent`.`members` (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO `resturent`.`members`
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09'); 
  
 #1.What is the total amount each customer spent at the restaurant?#
  
SELECT
a.customer_id,
SUM(price) AS total_sales
FROM
resturent.sales AS a
JOIN resturent.menu AS b
ON a.product_id = b.product_id
GROUP BY customer_id; 

#2.How many days has each customer visited the restaurant?# 

SELECT
customer_id,
COUNT(DISTINCT(order_date)) AS visit_count
FROM
resturent.sales
GROUP BY customer_id;

#3.What was the first item from the menu purchased by each customer? 

WITH ordered_sales_cte AS
(
 SELECT customer_id, order_date, product_name,
 DENSE_RANK() OVER(PARTITION BY a.customer_id
 ORDER BY a.order_date) AS ranks
 FROM resturent.sales AS a
 JOIN resturent.menu AS b
 ON a.product_id = b.product_id
)
SELECT customer_id, product_name
FROM ordered_sales_cte
WHERE ranks = 1
GROUP BY customer_id, product_name; 

#4.What is the most purchased item on the menu and how many times was it purchased by all customers? 

SELECT (COUNT(a.product_id)) AS most_purchased, product_name
FROM resturent.sales AS a
JOIN resturent.menu AS b
 ON a.product_id = b.product_id
GROUP BY a.product_id, product_name
ORDER BY most_purchased DESC
LIMIT 1; 

#5.Which item was the most popular one for each customer? 

WITH fav_item_cte AS
(
 SELECT a.customer_id, b.product_name,
 COUNT(b.product_id) AS order_count,
 DENSE_RANK() OVER(PARTITION BY a.customer_id
 ORDER BY COUNT(b.product_id) DESC) AS ranks
FROM resturent.menu AS b
JOIN resturent.sales AS a
 ON b.product_id = a.product_id
GROUP BY a.customer_id, b.product_name
)
SELECT customer_id, product_name, order_count
FROM fav_item_cte
WHERE ranks = 1; 

#6.Which item was purchased right before the customer became a member? 

WITH prior_member_purchased_cte AS
(
 SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
 DENSE_RANK() OVER(PARTITION BY s.customer_id
 ORDER BY s.order_date DESC) AS ranks
 FROM resturent.sales AS s
 JOIN resturent.members AS m
 ON s.customer_id = m.customer_id
 WHERE s.order_date < m.join_date
)
SELECT s.customer_id, s.order_date, a.product_name
FROM prior_member_purchased_cte AS s
JOIN resturent.menu AS a
 ON s.product_id = a.product_id
WHERE ranks = 1;
  
#7.Which item was purchased first by the customer after they became a member? 

WITH member_sales_cte AS
(
 SELECT b.customer_id, m.join_date, b.order_date, b.product_id,
 DENSE_RANK() OVER(PARTITION BY b.customer_id
 ORDER BY b.order_date) AS ranks
 FROM resturent.sales AS b
 JOIN resturent.members AS m
 ON b.customer_id = m.customer_id
 WHERE b.order_date = m.join_date
)
SELECT s.customer_id, s.order_date, a.product_name
FROM member_sales_cte AS s
JOIN resturent.menu AS a
 ON s.product_id = a.product_id;

#8.What is the total number of items and amount spent for each member before they became a member? 

SELECT
s.customer_id,
 COUNT(DISTINCT s.product_id) AS unique_menu_item,
 SUM(mm.price) AS total_sales
FROM
resturent.sales AS s
JOIN
resturent.members AS m
 ON s.customer_id = m.customer_id
JOIN
resturent.menu AS mm
 ON s.product_id = mm.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id;
