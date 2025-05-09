

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
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
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

  /* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


-- 1. What is the total amount each customer spent at the restaurant?
SELECT CUSTOMER_id,
	   SUM(price) AS TOTAL_SPENT 
	FROM
		SALES AS S 
        INNER JOIN MENU AS M
        ON S.PRODUCT_ID=M.PRODUCT_ID 
        GROUP BY CUSTOMER_ID;

-- 2. How many days has each customer visited the restaurant?
SELECT CUSTOMER_ID, 
COUNT(DISTINCT ORDER_DATE) 
	FROM SALES 
    GROUP BY CUSTOMER_ID 
    ORDER BY CUSTOMER_ID

-- 3. What was the first item from the menu purchased by each customer?
/* WHERE ORDER_TABLE IS OT */
SELECT CUSTOMER_ID, PRODUCT_NAME, ORDER_DATE  
FROM (
   SELECT CUSTOMER_ID, 
   ORDER_DATE, 
   PRODUCT_NAME,
   ROW_NUMBER () OVER (
    PARTITION BY CUSTOMER_ID
    ORDER BY ORDER_DATE
   ) AS RN 
   FROM SALES AS S
   INNER JOIN MENU AS M ON S.PRODUCT_ID=M.PRODUCT_ID
) AS OT 
WHERE RN=1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT  PRODUCT_NAME,
		COUNT(PRODUCT_NAME) AS NUMBER_SOLD, 
		RANK () OVER(ORDER BY COUNT(PRODUCT_NAME) DESC)
		FROM SALES AS S
		INNER JOIN MENU AS M ON S.PRODUCT_ID = M.PRODUCT_ID
		GROUP BY PRODUCT_NAME
		LIMIT 1

-- 5. Which item was the most popular for each customer?		
SELECT  CUSTOMER_ID,
		PRODUCT_NAME,
		COUNT(PRODUCT_NAME) AS NUMBER_SOLD, 
		ROW_NUMBER () OVER(PARTITION BY CUSTOMER_ID ORDER BY COUNT(PRODUCT_NAME) DESC)
		FROM SALES AS S
		INNER JOIN MENU AS M ON S.PRODUCT_ID = M.PRODUCT_ID
		GROUP BY PRODUCT_NAME, CUSTOMER_ID
		
-- 6. Which item was purchased first by the customer after they became a member?
SELECT  ORDER_DATE,
		CUSTOMER_ID,
		PRODUCT_NAME FROM 
		(
	SELECT  ORDER_DATE,
		S.CUSTOMER_ID,
		PRODUCT_NAME, 
		ROW_NUMBER () OVER(PARTITION BY S.CUSTOMER_ID ORDER BY ORDER_DATE) AS RN
		FROM SALES AS S
		INNER JOIN MENU AS MN ON S.PRODUCT_ID = MN.PRODUCT_ID
		LEFT JOIN MEMBERS AS M ON S.CUSTOMER_ID = M.CUSTOMER_ID
		WHERE ORDER_DATE >= JOIN_DATE
		GROUP BY PRODUCT_NAME, S.CUSTOMER_ID, ORDER_DATE 
 	   ) AS CTE
		WHERE RN = 1

-- 7. Which item was purchased just before the customer became a member?
SELECT  ORDER_DATE,
		CUSTOMER_ID,
		PRODUCT_NAME FROM 
		(
	SELECT  ORDER_DATE,
		S.CUSTOMER_ID,
		PRODUCT_NAME, 
		ROW_NUMBER () OVER(PARTITION BY S.CUSTOMER_ID ORDER BY ORDER_DATE) AS RN
		FROM SALES AS S
		INNER JOIN MENU AS MN ON S.PRODUCT_ID = MN.PRODUCT_ID
		LEFT JOIN MEMBERS AS M ON S.CUSTOMER_ID = M.CUSTOMER_ID
		WHERE ORDER_DATE < JOIN_DATE
		GROUP BY PRODUCT_NAME, S.CUSTOMER_ID, ORDER_DATE 
 	   ) AS CTE
		WHERE RN = 1

-- 8. What is the total items and amount spent for each member before they became a member?		
SELECT  S.CUSTOMER_ID,
		PRODUCT_NAME,
		COUNT (PRODUCT_NAME),
		SUM (PRICE)
		FROM SALES AS S
		INNER JOIN MENU AS MN ON S.PRODUCT_ID = MN.PRODUCT_ID
		LEFT JOIN MEMBERS AS M ON S.CUSTOMER_ID = M.CUSTOMER_ID
		WHERE ORDER_DATE < JOIN_DATE
		GROUP BY PRODUCT_NAME, S.CUSTOMER_ID

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
--     how many points would each customer have?
SELECT CUSTOMER_ID,
	   SUM 
	     (CASE
		 WHEN PRODUCT_NAME='sushi'
		 THEN PRICE * 10 * 2
		 ELSE PRICE * 10
		 END) AS TOTAL_POINT,
		 RANK () OVER(ORDER BY SUM (CASE
		 WHEN PRODUCT_NAME='sushi'
		 THEN PRICE * 10 * 2
		 ELSE PRICE * 10
		 END) DESC)
	     FROM SALES AS S
		 INNER JOIN MENU AS MN ON S.PRODUCT_ID = MN.PRODUCT_ID
		 GROUP BY CUSTOMER_ID 

/* 10. In the first week after a customer joins the program (including their join date) they earn 
   2x points on all items, not just sushi - how many points do customer A and B have at the 
   end of January? */ 

	SELECT S.CUSTOMER_ID,
	   SUM 
	     (CASE
		 WHEN ORDER_DATE BETWEEN JOIN_DATE AND JOIN_DATE + INTERVAL '7 DAYS'
		 THEN PRICE * 10 * 2
		 ELSE PRICE * 10
		 END) AS TOTAL_POINT
	     FROM SALES AS S
		 INNER JOIN MENU AS MN ON S.PRODUCT_ID = MN.PRODUCT_ID
		 LEFT JOIN MEMBERS AS M ON S.CUSTOMER_ID = M.CUSTOMER_ID
		 WHERE S.CUSTOMER_ID IN ('A','B')
		 AND ORDER_DATE BETWEEN '2021-01-01' AND '2021-01-31'
		 GROUP BY S.CUSTOMER_ID 	

/* BONUS; This table presents a detailed log of customer transactions, showing each customer's ID, 
   the date of purchase, the specific product purchased, its price, and whether the customer was a 
   registered member (Y/N) at the time of the order. */

   SELECT S.CUSTOMER_ID,
   	      ORDER_DATE,
		  PRODUCT_NAME,
		  PRICE,
		  CASE 
		    WHEN JOIN_DATE <= ORDER_DATE THEN 'Y'
		    ELSE 'N'
			END AS MEMBER
		  FROM SALES AS S
		  INNER JOIN MENU AS MN ON S.PRODUCT_ID = MN.PRODUCT_ID
		  LEFT JOIN MEMBERS AS M ON S.CUSTOMER_ID = M.CUSTOMER_ID

-- BONUS; This table ranks customer product purchases made after joining the loyalty program.

   SELECT R.CUSTOMER_ID,
          ORDER_DATE,
		  PRODUCT_NAME,
		  PRICE,
		  MEMBER,
		  CASE 
		    WHEN MEMBER != 'N' THEN 
		    RANK () OVER (PARTITION BY R.CUSTOMER_ID, MEMBER ORDER BY ORDER_DATE)
			ELSE NULL
			END AS RANKING
		  FROM ( SELECT S.*,
		  				JOIN_DATE,
		  				CASE 
						  WHEN JOIN_DATE <= ORDER_DATE THEN 'Y'
		  				  ELSE 'N'
						  END AS MEMBER
		   				FROM SALES AS S
						LEFT JOIN MEMBERS AS M ON S.CUSTOMER_ID = M.CUSTOMER_ID) AS R
		  INNER JOIN MENU AS MN ON R.PRODUCT_ID = MN.PRODUCT_ID
		  	

