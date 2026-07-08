-- oracle sql
SELECT
    CH.CHANNEL_CLASS,
    CH.CHANNEL_TOTAL,
    CC.UNIT_COST,
    SUM(CC.UNIT_COST) TOTAL_COST,
    CC.TIME_ID
FROM
         SH.CHANNELS CH
    INNER JOIN SH.COSTS CC ON CH.CHANNEL_ID = CC.CHANNEL_ID
GROUP BY
    CH.CHANNEL_CLASS,
    CH.CHANNEL_TOTAL,
    CC.UNIT_COST,
    CC.TIME_ID

---customer table
SELECT * FROM SH.CUSTOMERS

SELECT 
COUNT(DISTINCT(CUST_ID)) AS Number_OF_CUSTOMER,
COUNT(DISTINCT(CUST_GENDER)) AS GEMDER,
COUNT(DISTINCT(CUST_MARITAL_STATUS)) AS CUST_STATUS
FROM SH.CUSTOMERS

--- COUNT CUST_MARITAL_STATUS

SELECT CUST_MARITAL_STATUS,
COUNT(*) AS TOTAL_COUNT
FROM SH.CUSTOMERS
WHERE CUST_MARITAL_STATUS IS NOT NULL
GROUP BY CUST_MARITAL_STATUS


--- CUST_GENDER
SELECT CUST_GENDER,
COUNT(*)
    AS
    TOTAL_COUNT
    FROM
    SH.CUSTOMERS
    GROUP
    BY
    CUST_GENDER

--- cuntries 
    SELECT * FROM
    SH.COUNTRIES
    SELECT * FROM
    SH.SALES

-------- Sales

SELECT
    CONCAT
    ( CS.CUST_FIRST_NAME, ' ', CS.CUST_LAST_NAME )
        AS
    CUST_NAME, CS.CUST_GENDER, CS.CUST_STATE_PROVINCE, SUM ( S.AMOUNT_SOLD * S.QUANTITY_SOLD )
    AS
    TOTAL_COST, S.TIME_ID
FROM
    SH.CUSTOMERS
    CS
INNER JOIN
    SH.SALES
    S
    ON
    CS.CUST_ID = S.CUST_ID
WHERE
    S.QUANTITY_SOLD > 0
GROUP BY
    CONCAT ( CS.CUST_FIRST_NAME, ' ',
    CS.CUST_LAST_NAME ),
    CS.CUST_GENDER,
    CS.CUST_STATE_PROVINCE,
    S.TIME_ID
ORDER BY TOTAL_COST DESC

----
SELECT 
    CUST_CITY,
    CS.CUST_GENDER,
    SUM(S.AMOUNT_SOLD * S.QUANTITY_SOLD) AS TOTAL_COST,
    S.TIME_ID
FROM SH.CUSTOMERS CS
INNER JOIN SH.SALES S
    ON CS.CUST_ID = S.CUST_ID
WHERE S.QUANTITY_SOLD > 0
GROUP BY
    CUST_CITY,
    CS.CUST_GENDER,
    S.TIME_ID
ORDER BY TOTAL_COST DESC

-- 1. Top 5 Cities by Total Sales for Each Gender

WITH CitySales AS (
    SELECT
        CS.CUST_CITY,
        CS.CUST_GENDER,
        SUM(S.AMOUNT_SOLD) AS TOTAL_SALES
    FROM SH.CUSTOMERS CS
    JOIN SH.SALES S
        ON CS.CUST_ID = S.CUST_ID
    GROUP BY
        CS.CUST_CITY,
        CS.CUST_GENDER
)
SELECT *
FROM (
    SELECT
        CUST_CITY,
        CUST_GENDER,
        TOTAL_SALES,
        DENSE_RANK() OVER (
            PARTITION BY CUST_GENDER
            ORDER BY TOTAL_SALES DESC
        ) AS SALES_RANK
    FROM CitySales
)
WHERE SALES_RANK <= 5;

-- 2.Monthly Sales with Running Total
SELECT
    S.TIME_ID,
    SUM(S.AMOUNT_SOLD) AS MONTHLY_SALES,
    SUM(SUM(S.AMOUNT_SOLD))
        OVER (ORDER BY S.TIME_ID) AS RUNNING_TOTAL
FROM SH.SALES S
GROUP BY S.TIME_ID
ORDER BY S.TIME_ID;


-- 3.Average Sales by Gender Compared with Overall Average
SELECT
    CS.CUST_GENDER,
    AVG(S.AMOUNT_SOLD) AS GENDER_AVG,
    (
        SELECT AVG(AMOUNT_SOLD)
        FROM SH.SALES
    ) AS OVERALL_AVG
FROM SH.CUSTOMERS CS
JOIN SH.SALES S
    ON CS.CUST_ID = S.CUST_ID
GROUP BY CS.CUST_GENDER;

-- 4.Customers Whose Sales Are Above Their City's Average
SELECT
    CS.CUST_ID,
    CS.CUST_CITY,
    SUM(S.AMOUNT_SOLD) AS CUSTOMER_TOTAL
FROM SH.CUSTOMERS CS
JOIN SH.SALES S
    ON CS.CUST_ID = S.CUST_ID
GROUP BY
    CS.CUST_ID,
    CS.CUST_CITY
HAVING SUM(S.AMOUNT_SOLD) >
(
    SELECT AVG(CITY_TOTAL)
    FROM (
        SELECT
            CUST_CITY,
            SUM(S2.AMOUNT_SOLD) AS CITY_TOTAL
        FROM SH.CUSTOMERS C2
        JOIN SH.SALES S2
            ON C2.CUST_ID = S2.CUST_ID
        GROUP BY CUST_CITY
    )
);

---5. Rank Customers by Total Purchases
SELECT
    CS.CUST_ID,
    CS.CUST_CITY,
    SUM(S.AMOUNT_SOLD) AS TOTAL_SALES,
    RANK() OVER (
        ORDER BY SUM(S.AMOUNT_SOLD) DESC
    ) AS SALES_RANK
FROM SH.CUSTOMERS CS
JOIN SH.SALES S
    ON CS.CUST_ID = S.CUST_ID
GROUP BY
    CS.CUST_ID,
    CS.CUST_CITY;


-- 6.Sales Contribution Percentage by City
SELECT
    CS.CUST_CITY,
    SUM(S.AMOUNT_SOLD) AS CITY_SALES,
    ROUND(
        SUM(S.AMOUNT_SOLD) /
        SUM(SUM(S.AMOUNT_SOLD)) OVER () * 100,
        2
    ) AS PERCENT_OF_TOTAL
FROM SH.CUSTOMERS CS
JOIN SH.SALES S
    ON CS.CUST_ID = S.CUST_ID
GROUP BY CS.CUST_CITY
ORDER BY CITY_SALES DESC;


-- 7.Pivot Sales by Gender
SELECT *
FROM (
    SELECT
        CS.CUST_CITY,
        CS.CUST_GENDER,
        S.AMOUNT_SOLD
    FROM SH.CUSTOMERS CS
    JOIN SH.SALES S
        ON CS.CUST_ID = S.CUST_ID
)
PIVOT (
    SUM(AMOUNT_SOLD)
    FOR CUST_GENDER IN (
        'M' AS MALE,
        'F' AS FEMALE
    )
)
ORDER BY CUST_CITY;

-- 8. Year-over-Year Sales Growth
SELECT
    S.TIME_ID,
    SUM(S.AMOUNT_SOLD) AS TOTAL_SALES,
    LAG(SUM(S.AMOUNT_SOLD))
        OVER (ORDER BY S.TIME_ID) AS PREVIOUS_SALES,
    ROUND(
        (
            SUM(S.AMOUNT_SOLD) -
            LAG(SUM(S.AMOUNT_SOLD))
            OVER (ORDER BY S.TIME_ID)
        ) /
        LAG(SUM(S.AMOUNT_SOLD))
        OVER (ORDER BY S.TIME_ID) * 100,
        2
    ) AS GROWTH_PERCENT
FROM SH.SALES S
GROUP BY S.TIME_ID
ORDER BY S.TIME_ID;


-- 9. Highest Spending Customer in Each City
WITH CustomerSales AS (
    SELECT
        CS.CUST_CITY,
        CS.CUST_ID,
        SUM(S.AMOUNT_SOLD) AS TOTAL_SALES
    FROM SH.CUSTOMERS CS
    JOIN SH.SALES S
        ON CS.CUST_ID = S.CUST_ID
    GROUP BY
        CS.CUST_CITY,
        CS.CUST_ID
)
SELECT *
FROM (
    SELECT
        CUST_CITY,
        CUST_ID,
        TOTAL_SALES,
        ROW_NUMBER() OVER (
            PARTITION BY CUST_CITY
            ORDER BY TOTAL_SALES DESC
        ) AS RN
    FROM CustomerSales
)
WHERE RN = 1;

--10. Sales Summary Using ROLLUP
SELECT
    CS.CUST_CITY,
    CS.CUST_GENDER,
    SUM(S.AMOUNT_SOLD) AS TOTAL_SALES
FROM SH.CUSTOMERS CS
JOIN SH.SALES S
    ON CS.CUST_ID = S.CUST_ID
GROUP BY ROLLUP (
    CS.CUST_CITY,
    CS.CUST_GENDER
)
ORDER BY
    CS.CUST_CITY,
    CS.CUST_GENDER;


/* These queries showcase advanced SQL concepts commonly tested in interviews and used in analytics
 projects, including:

- Common Table Expressions (CTEs)
- Window (analytic) functions (RANK, DENSE_RANK, ROW_NUMBER, LAG)
- Subqueries
- HAVING with aggregate comparisons
- ROLLUP and PIVOT
- Running totals
- Percentage calculations
- Ranking within groups */

/* The SQL query analyzes customer sales by joining the **CUSTOMERS** and **SALES** tables in
 the Oracle SH schema. It calculates the total sales amount for each combination of customer city,
  customer gender, and time period (`TIME_ID`). The query filters out records with non-positive 
  quantities, groups the data by city, gender, and time, and sorts the results in descending 
  order of total sales. This analysis helps identify which cities and customer genders generate 
  the highest sales over time, providing valuable insights for sales performance evaluation, 
  customer segmentation, and business decision-making.  */