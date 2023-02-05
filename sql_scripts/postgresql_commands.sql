-- find events with no corresponding venue
CREATE SCHEMA saas;

CREATE TABLE saas.venue(
	venueid smallint not null,
	venuename varchar(100),
	venuecity varchar(30),
	venuestate char(2),
	venueseats integer);

CREATE TABLE saas.category(
	catid smallint not null,
	catgroup varchar(10),
	catname varchar(10),
	catdesc varchar(50));

CREATE TABLE saas.event(
	eventid integer not null,
	venueid smallint not null,
	catid smallint not null,
	dateid smallint not null,
	eventname varchar(200),
	starttime timestamp);

VACUUM ANALYZE;
VACUUM FULL;

-- UPDATE public.date
-- SET month = 12
-- WHERE month = 'DEC';

SELECT *
FROM event
WHERE venueid NOT IN (
    SELECT venueid
    FROM venue);

-- Get row counts for all tables
SELECT schemaname, relname, n_live_tup
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_live_tup DESC;

-- Find total sales on a given calendar date.
SELECT sum(qtysold)
FROM sales,
     date
WHERE sales.dateid = date.dateid
  AND caldate = '2020-01-05';

-- Find top 10 buyers by quantity.
SELECT firstname, lastname, total_quantity
FROM (
         SELECT buyerid, sum(qtysold) AS total_quantity
         FROM sales
         GROUP BY buyerid
         ORDER BY total_quantity DESC
         limit 10) AS q,
     users
WHERE q.buyerid = userid
ORDER BY q.total_quantity DESC;

-- Find events in the 99.9 percentile in terms of all time gross sales.
SELECT eventname, total_price
FROM (SELECT eventid, total_price, ntile(1000) OVER (ORDER BY total_price DESC) AS percentile
      FROM (SELECT eventid, sum(pricepaid) AS total_price
            FROM sales
            GROUP BY eventid) AS S) AS Q,
     event E
WHERE Q.eventid = E.eventid
  AND percentile = 1
ORDER BY total_price DESC;

SELECT d.year,
       d.month,
       cast(sum(s.pricepaid * s.qtysold) as money) AS sum_sales,
       cast(sum(s.commission) as money)            AS sum_commission,
       count(*)                                    AS order_volume
FROM date AS d,
     sales AS s
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- same query ran from Athena in demo
-- seven joins across 6 tables
WITH cat AS (
    SELECT DISTINCT e.eventid,
                    c.catgroup,
                    c.catname
    FROM event AS e
             LEFT JOIN category AS c ON c.catid = e.catid
)
SELECT d.caldate,
       s.pricepaid,
       s.qtysold,
       round(s.pricepaid * s.qtysold, 2)      AS sale_amount,
       s.commission,
       e.eventname,
       concat(u1.firstname, ' ', u1.lastname) AS seller,
       concat(u2.firstname, ' ', u2.lastname) AS buyer,
       c.catname                              AS bucket_catname,
       c.catgroup,
       c.catname
FROM sales AS s
         LEFT JOIN listing AS l ON l.listid = s.listid
         LEFT JOIN users AS u1 ON u1.userid = s.sellerid
         LEFT JOIN users AS u2 ON u2.userid = s.buyerid
         LEFT JOIN event AS e ON e.eventid = s.eventid
         LEFT JOIN date AS d ON d.dateid = s.dateid
         LEFT JOIN cat AS c ON c.eventid = s.eventid
ORDER BY caldate, sale_amount;