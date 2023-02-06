-- Reference: https://www.geeksforgeeks.org/loops-in-mysql/
-- 14 m 57 s per 1K new records
-- 2 h 20 m 43 s per 10K new records

DELIMITER $$

DROP PROCEDURE IF EXISTS ADD_SYNTHETIC_SALES;

CREATE PROCEDURE ADD_SYNTHETIC_SALES()
BEGIN
    DECLARE a INT Default 1;
    sales_loop:
    LOOP
        INSERT INTO sale (salesid,
                          listid,
                          sellerid,
                          buyerid,
                          eventid,
                          dateid,
                          qtysold,
                          pricepaid,
                          commission,
                          saletime)
        SELECT *
        FROM (SELECT MAX(salesid) + 1
              FROM sale) as salesid,
             (SELECT listid
              FROM sale
              ORDER BY RAND()
              LIMIT 1) AS listid,
             (SELECT sellerid
              FROM sale
              ORDER BY RAND()
              LIMIT 1) AS sellerid,
             (SELECT buyerid
              FROM sale
              ORDER BY RAND()
              LIMIT 1) AS buyerid,
             (SELECT eventid
              FROM sale
              ORDER BY RAND()
              LIMIT 1) AS eventid,
             (SELECT dateid
              FROM sale
              ORDER BY RAND()
              LIMIT 1) AS dateid,
             (SELECT qtysold
              FROM sale
              ORDER BY RAND()
              LIMIT 1) AS qtysold,
             (SELECT pricepaid
              FROM sale
              ORDER BY RAND()
              LIMIT 1) AS pricepaid,
             (SELECT commission
              FROM sale
              ORDER BY RAND()
              LIMIT 1) AS commission,
             (SELECT saletime
              FROM sale
              ORDER BY RAND()
              LIMIT 1) AS saletime;

        SET a = a + 1;

        IF a = 10000 THEN
            LEAVE sales_loop;
        END IF;
    END LOOP sales_loop;
END $$

CALL ADD_SYNTHETIC_SALES();