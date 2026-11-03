-- ********************** Checking the data ************************

SELECT
    *
FROM subscriptions;



-- ********************** Clean status columns & Check active subscribers ************************

SELECT
    DISTINCT status
FROM subscriptions;


WITH status_ok AS (
    SELECT
        *,
        CASE
            WHEN LOWER(status) LIKE '%active%' THEN 'Active'
            WHEN LOWER(status) LIKE '%cancel%' THEN 'Cancelled'
            WHEN LOWER(status) LIKE '%pause%' THEN 'Paused'
        END AS cleaned_status
    FROM subscriptions)
SELECT
    cleaned_status,
    COUNT(DISTINCT subscription_id) AS total_subscriptions,
    SUM(monthly_price) AS mrr                                      -- This information is not correct as data still needs to be clenaed
FROM status_ok
GROUP BY 1;


-- ********************** 6C Framework ************************

-- ********************** Completeness ************************
-- ************ Are all the necessary values there? ***********

SELECT
    COUNT(*) AS total_rows,
    COUNT(CASE WHEN TRIM(customer_email) = '' THEN 1 END) AS missing_emails,
    COUNT(CASE WHEN TRIM(start_date) = '' THEN 1 END) AS missing_start_date,
    COUNT(CASE WHEN TRIM(end_date) = '' THEN 1 END) AS missing_end_date,
    COUNT(CASE WHEN TRIM(payment_method) = '' THEN 1 END) AS missing_payment_method
FROM subscriptions;

SELECT
    payment_method,
    COUNT(*) AS total_rows
FROM subscriptions
GROUP BY payment_method
ORDER BY 2 DESC;

SELECT
    payment_method,
    CASE
        WHEN payment_method = 'NULL' OR payment_method = 'N/A' OR payment_method = '' THEN 'Unknown'
        ELSE payment_method
    END AS cleaned_payment_method
FROM subscriptions;


-- ********************** Consistency ************************
-- ****** Is the same info always written the same way? ******

SELECT
    plan,
    COUNT(*) AS qty_rows
FROM subscriptions
GROUP BY plan
ORDER BY 2 DESC;

SELECT
    DISTINCT(plan_cleaned)
FROM (
    SELECT
        UPPER(SUBSTR(TRIM(plan), 1, 1)) || LOWER(SUBSTR(TRIM(plan), 2)) AS plan_cleaned
    FROM subscriptions);


SELECT
    country,
    COUNT(*) AS qty_rows
FROM subscriptions
GROUP BY country
ORDER BY 2 DESC;


SELECT 
    country_cleaned,
    COUNT(*) AS qty_rowls
FROM (
    SELECT
        country,
        CASE
            WHEN LOWER(country) LIKE '%italy%' OR LOWER(country) LIKE '%it%' THEN 'Italy'
            WHEN LOWER(country) LIKE '%u%' THEN 'United Kingdom'
            WHEN LOWER(country) LIKE '%germany%' OR LOWER(country) LIKE '%de%' THEN 'Germany'
            WHEN LOWER(country) LIKE '%ireland%' or LOWER(country) LIKE '%ie%' THEN 'Ireland'
            ELSE 'Unknown'
        END AS country_cleaned
    FROM subscriptions)
GROUP BY country_cleaned;


SELECT
    start_date,
    COUNT(*) AS qty_rows
FROM subscriptions
GROUP BY start_date
ORDER BY 2 DESC;


SELECT
    start_date,
    CASE
        WHEN start_date LIKE '____-__-__' THEN date(start_date)
        WHEN start_date LIKE '__/__/____' THEN date(
            substr(start_date, 7, 4) || '-' ||
            substr(start_date, 4, 2) || '-' ||
            substr(start_date, 1, 2)
        )
    END AS start_date_cleaned
FROM subscriptions;