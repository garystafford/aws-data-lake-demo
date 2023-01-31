-- save as view - view_sales_by_month
SELECT d.year,
    d.month_int,
    round(sum(cast(s.pricepaid AS DECIMAL(8,2)) * s.qtysold), 2) AS sum_sales,
    round(sum(cast(s.commission AS DECIMAL(8,2))), 2) AS sum_commission,
    count(*) AS order_volume
FROM silver_ecomm_sale AS s
    JOIN silver_ecomm_date AS d USING(dateid)
GROUP BY d.year,
    d.month_int
ORDER BY d.year,
    d.month_int;


-- ctas gold/curated #1
CREATE TABLE IF NOT EXISTS gold_sales_by_category
WITH (
    format = 'Parquet',
    write_compression = 'SNAPPY',
    external_location = 's3://open-data-lake-demo-us-east-1/tickit/gold/gold_sales_by_category/',
    partitioned_by = ARRAY [ 'catgroup',
    'catname' ],
    bucketed_by = ARRAY [ 'bucket_catname' ],
    bucket_count = 1
)
AS WITH cat AS (
    SELECT DISTINCT e.eventid,
        c.catgroup,
        c.catname
    FROM silver_tickit_ems_event AS e
        LEFT JOIN silver_tickit_ems_category AS c ON c.catid = e.catid
)
SELECT cast(d.caldate AS DATE) AS caldate,
    s.pricepaid,
    s.qtysold,
    round(cast(s.pricepaid AS DECIMAL(8,2)) * s.qtysold, 2) AS sale_amount,
    cast(s.commission AS DECIMAL(8,2)) AS commission,
    round((cast(s.commission AS DECIMAL(8,2)) / (cast(s.pricepaid AS DECIMAL(8,2)) * s.qtysold)) * 100, 2) AS commission_prcnt,
    e.eventname,
    concat(u1.firstname, ' ', u1.lastname) AS seller,
    concat(u2.firstname, ' ', u2.lastname) AS buyer,
    c.catname AS bucket_catname,
    c.catgroup,
    c.catname
FROM silver_ecomm_sale AS s
    LEFT JOIN silver_ecomm_listing AS l ON l.listid = s.listid
    LEFT JOIN silver_tickit_crm_user AS u1 ON u1.userid = s.sellerid
    LEFT JOIN silver_tickit_crm_user AS u2 ON u2.userid = s.buyerid
    LEFT JOIN silver_tickit_ems_event AS e ON e.eventid = s.eventid
    LEFT JOIN silver_ecomm_date AS d ON d.dateid = s.dateid
    LEFT JOIN cat AS c ON c.eventid = s.eventid;


-- ctas gold/curated #2
CREATE TABLE IF NOT EXISTS gold_sales_by_date
WITH (
    format = 'Parquet',
    write_compression = 'SNAPPY',
    external_location = 's3://open-data-lake-demo-us-east-1/tickit/gold/gold_sales_by_date/',
    partitioned_by = ARRAY [ 'year', 'month'],
    bucketed_by = ARRAY [ 'bucket_month' ],
    bucket_count = 1
)
AS WITH cat AS (
    SELECT DISTINCT e.eventid,
        c.catgroup,
        c.catname
    FROM silver_tickit_ems_event AS e
        LEFT JOIN silver_tickit_ems_category AS c ON c.catid = e.catid
)
SELECT cast(d.caldate AS DATE) AS caldate,
    s.pricepaid,
    s.qtysold,
    round(cast(s.pricepaid AS DECIMAL(8,2)) * s.qtysold, 2) AS sale_amount,
    cast(s.commission AS DECIMAL(8,2)) AS commission,
    round((cast(s.commission AS DECIMAL(8,2)) / (cast(s.pricepaid AS DECIMAL(8,2)) * s.qtysold)) * 100, 2) AS commission_prcnt,
    e.eventname,
    concat(u1.firstname, ' ', u1.lastname) AS seller,
    concat(u2.firstname, ' ', u2.lastname) AS buyer,
    c.catgroup,
    c.catname,
    d.month_int AS bucket_month,
    d.year,
    d.month_int as month
FROM silver_ecomm_sale AS s
    LEFT JOIN silver_ecomm_listing AS l ON l.listid = s.listid
    LEFT JOIN silver_tickit_crm_user AS u1 ON u1.userid = s.sellerid
    LEFT JOIN silver_tickit_crm_user AS u2 ON u2.userid = s.buyerid
    LEFT JOIN silver_tickit_ems_event AS e ON e.eventid = s.eventid
    LEFT JOIN silver_ecomm_date AS d ON d.dateid = s.dateid
    LEFT JOIN cat AS c ON c.eventid = s.eventid;


SELECT * FROM gold_sales_by_date
WHERE catgroup = 'Concerts'
LIMIT 10;


-- query gold/agg data
-- save as view - view_agg_sales_by_month
SELECT year(caldate) AS sales_year,
    month(caldate) AS sales_month,
    round(sum(sale_amount), 2) AS sum_sales,
    round(sum(commission), 2) AS sum_commission,
    count(*) AS order_volume
FROM gold_sales_by_category
GROUP BY year(caldate),
    month(caldate)
ORDER BY year(caldate),
    month(caldate);


SELECT year(caldate) AS sales_year,
    month(caldate) AS sales_month,
    round(sum(sale_amount), 2) AS sum_sales,
    round(sum(commission), 2) AS sum_commission,
    count(*) AS order_volume
FROM gold_sales_by_date
GROUP BY year(caldate),
    month(caldate)
ORDER BY year(caldate),
    month(caldate);


-- efficiency of partitions and columns with Parquet
SELECT *
FROM "data_lake_demo"."gold_sales_by_category"
LIMIT 150000;

SELECT *
FROM "data_lake_demo"."gold_sales_by_category"
WHERE catgroup = 'Shows'
LIMIT 150000;

FROM "data_lake_demo"."gold_sales_by_category"
WHERE catgroup = 'Shows' AND catname = 'Opera'
LIMIT 150000;

SELECT caldate, sale_amount, commission
FROM "data_lake_demo"."gold_sales_by_category"
WHERE catgroup = 'Shows' AND catname = 'Opera'
LIMIT 150000;