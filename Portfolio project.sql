use zomato;

SELECT * FROM Zomato.users;
SELECT * FROM Zomato.sales;
SELECT * FROM Zomato.product;
SELECT * FROM Zomato.goldusers_signup;

-- what is the total amount each customer has spent on zomato?

SELECT 
    m1.userid, SUM(price) AS total_amount
FROM
    users m1
        JOIN
    sales m2 ON m1.userid = m2.userid
        JOIN
    product m3 ON m2.product_id = m3.product_id
GROUP BY m1.userid;


output:  
    
userid	total_amount
1	      4180.00
2	      2240.00
3	      3220.00


-- how many days has each customer visited zomato?

SELECT DISTINCT
    (userid), COUNT(created_date) AS distinct_days
FROM
    sales
GROUP BY userid;

output:

    
userid	distinct_days
1	         7
2	         5
3	         7

--  what was the first product purchased by each customer?

select * from (
select m1.userid,m1.created_date,m2.product_id, rank() over(partition by userid order by created_date) as ranking from sales m1
join product m2
on m1.product_id=m2.product_id) t
where t.ranking=1;

OUTPUT

userid	created_date	product_id
1	    2016-05-20	           3
2	    2017-09-24	           1
3	    2016-12-07	           2




-- what is the most purchased item on the menu and how many times was it purchased by all the cusotmers?


SELECT 
    userid, COUNT(Product_id) AS cnt
FROM
    sales
WHERE
    product_id = (SELECT 
            product_id
        FROM
            sales
        GROUP BY userid
        ORDER BY COUNT(product_id) DESC
        LIMIT 1)
GROUP BY userid;

output:

product_id	cnt
2	         7


-- which item is most popular for each customer

select * from (
select *, rank() over(partition by userid order by cnt desc) as ranking from 
(select userid, product_id ,count(product_id) as cnt from sales
group by userid, product_id)a)b 
where ranking=1;



userid	product_id	cnt
1	        2	     5
2	        2	     3
3	        2	     5

-- which item was purchased first by the customer after they became  a member?

select x.* ,rank() over(partition by userid order by created_date) as ranking from 
(SELECT m1.userid,m2.created_date, m2.product_id, m1.gold_signup_date FROM Zomato.goldusers_signup m1
join sales m2
on m1.userid=m2.userid
where m1.gold_signup_date>created_date
group by m1.userid) x
;

userid	created_date	product_id	ranking
1	     2017-03-11	          2	     1
3	     2019-12-18	          1	     1


-- which item was purchased just before the customer became a member?
select y.* from (
(select x.*,  rank() over(partition by userid order by  created_date) as dates from 
(select m1.userid,m1.gold_signup_date, m2.created_date from goldusers_signup m1
join sales m2
on m1.userid=m2.userid
where m2.created_date<= m1.gold_signup_date) x)y)
where dates=1;


userid	gold_signup_date	created_date
1	       2017-09-22	     2016-11-09
3	       2017-04-21	     2016-12-20

-- what is the total orders and amount spend for each memeber before they became a member?

SELECT 
    userid, COUNT(*) AS total_orders, SUM(price) AS total_amount
FROM
    (SELECT 
        a.*, d.price
    FROM
        (SELECT 
        m1.userid,
            m1.gold_signup_date,
            m2.created_date,
            m2.product_id
    FROM
        goldusers_signup m1
    JOIN sales m2 ON m1.userid = m2.userid
    WHERE
        m2.created_date <= m1.gold_signup_date) a
    INNER JOIN product d ON a.product_id = d.product_id) x
GROUP BY userid;

userid	total_orders	total_amount
1	         7	          4180.00
2	         5	          2240.00
3	         7	          3220.00




-- if buying each geneartes points for eg 5rs =2 points and each product has different purchasing points 
-- for eg for p1 5rs =1 zomato point , for p2 10rs = 5zomato point and p3 5= 1 zomato point 
-- calculate points collected by each customers and for which product most points has been given till now.
SELECT 
    f.userid, SUM(total_points)
FROM
    (SELECT 
        e.*, amount / points AS total_points
    FROM
        (SELECT 
        d.*,
            CASE
                WHEN product_id = 1 THEN 5
                WHEN product_id = 2 THEN 2
                WHEN product_id = 3 THEN 5
                ELSE 0
            END AS points
    FROM
        (SELECT 
        c.userid, c.product_id, c.Price, SUM(c.Price) AS amount
    FROM
        (SELECT 
        m2.*, m1.price
    FROM
        sales m2
    INNER JOIN product m1 ON m2.product_id = m1.product_id) c
    GROUP BY c.userid , c.product_id) d) e) f
GROUP BY f.userid;

-- for product 

SELECT 
    f.product_id, SUM(total_points) AS total_points
FROM
    (SELECT 
        e.*, amount / points AS total_points
    FROM
        (SELECT 
        d.*,
            CASE
                WHEN product_id = 1 THEN 5
                WHEN product_id = 2 THEN 2
                WHEN product_id = 3 THEN 5
                ELSE 0
            END AS points
    FROM
        (SELECT 
        c.userid, c.product_id, c.Price, SUM(c.Price) AS amount
    FROM
        (SELECT 
        m2.*, m1.price
    FROM
        sales m2
    INNER JOIN product m1 ON m2.product_id = m1.product_id) c
    GROUP BY c.userid , c.product_id) d) e) f
GROUP BY f.product_id
ORDER BY total_points DESC;

output :

    serid	total_points
      1	       88
      2	       18
      3	       45

-- 11 rank all the transaction of the customers

select m1.userid, m2.price, created_date,
rank() over(partition by userid order by created_date Desc)
from sales m1
inner join product m2
on m1.product_id=m2.product_id;

OUTPUT: 
    '1','870','2019-10-23','1'
'1','330','2018-03-19','2'
'1','870','2017-04-19','3'
'1','870','2017-03-11','4'
'1','980','2016-11-09','5'
'1','330','2016-05-20','6'
'1','980','2016-03-11','7'
'2','330','2020-07-20','1'
'2','330','2018-09-10','2'
'2','870','2017-11-08','3'
'2','980','2017-09-24','4'
'3','980','2019-12-18','1'
'3','870','2017-12-07','2'
'3','870','2016-12-20','3'
'3','870','2016-12-15','4'
'3','980','2016-11-10','5'




-- 12 rank all the transactions for each member whenever they are a zomato gold member for every non gold member transaction as na;



SELECT e.*, CASE WHEN e.ranking = '0' THEN 'NA' ELSE e.ranking END AS ranking
FROM (SELECT c.*, CAST((CASE WHEN gold_signup_date IS NULL THEN 0 ELSE 
RANK() OVER (PARTITION BY userid ORDER BY created_date DESC) END) AS CHAR) AS ranking
FROM (SELECT m1.userid, m1.created_date, m2.gold_signup_date FROM sales m1
LEFT JOIN goldusers_signup m2
ON m1.userid = m2.userid
AND m1.created_date >= m2.gold_signup_date) c) e;

OUTPUT:
userid created_date gold_signup_date ranking ranking
1       2019-10-23     2017-09-22           1    1
1       2018-03-19     2017-09-22           2    2
1       2017-04-19     NULL                 0    NA
1       2017-03-11     NULL                 0    NA
1       2016-11-09     NULL                 0    NA
1       2016-05-20     NULL                 0    NA
1       2016-03-11     NULL                 0    NA
2       2020-07-20     NULL                 0    NA
2       2018-09-10     NULL                 0    NA
2       2017-11-08     NULL                 0    NA
2       2017-09-24     NULL                 0    NA
3       2019-12-18     2017-04-21           1    1
3       2017-12-07     2017-04-21           2    2
3       2016-12-20     NULL                 0    NA
3       2016-12-15     NULL                 0    NA
3       2016-11-10     NULL                 0    NA



