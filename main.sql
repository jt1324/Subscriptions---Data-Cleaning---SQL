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

-- plan
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


-- country
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


-- start_date
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


-- ********************** Correctness ************************
-- *************** Are the values possible? ******************

-- Checking columns data type
SELECT monthly_price, typeof(monthly_price), start_date, typeof(start_date)
FROM subscriptions
LIMIT 10;

-- monthly_price
SELECT
    monthly_price,
    COUNT(*) AS qty
FROM subscriptions
GROUP BY 1
ORDER BY 2 DESC;

WITH done AS (
    WITH integ AS (
        SELECT
            CAST(monthly_price AS REAL) AS monthly_price
        FROM subscriptions)
    SELECT
        monthly_price,
        CASE
            WHEN monthly_price < 0 THEN monthly_price * -1
            WHEN monthly_price > 100 then monthly_price / 100
            ELSE monthly_price
        END AS monthly_price_cleaned
    FROM integ
)
SELECT
    monthly_price_cleaned,
    COUNT(*)
FROM done
GROUP BY 1
ORDER BY 2 DESC;


-- ******************************************** Conformity **********************************************
-- *************** Does the data follow the businnes rules? - One row per subscription ******************

-- Identifying duplications
SELECT
    subscription_id,
    COUNT(*) AS qty
FROM subscriptions
GROUP BY 1
HAVING COUNT(*) > 1
ORDER BY 2 DESC;

SELECT
    *
FROM subscriptions
WHERE subscription_id = 'SUB-1132';


WITH row_n AS (
    SELECT
        *,
        ROW_NUMBER() OVER(
            PARTITION BY subscription_id
                ORDER BY updated_at DESC
        ) AS rn
    FROM subscriptions
)
SELECT
    *
FROM row_n
WHERE rn = 1; 


-- ******************************************** Coherence **********************************************
-- **** Do related columns make sense together? - Columns can look ok but contradict its neighbour *****

SELECT
    *
FROM subscriptions;

SELECT
    *,
    CASE
        WHEN LOWER(TRIM(status)) LIKE '%active%' AND TRIM(end_date) <> '' THEN 'active with end date'
        WHEN LOWER(TRIM(status)) LIKE '%cancel%' AND TRIM(end_date) = '' THEN 'cancelled with no end date'
        WHEN LOWER(TRIM(plan)) NOT LIKE '%free%' AND monthly_price = '0.00' THEN 'paid plan without charges'
        WHEN LOWER(TRIM(plan)) LIKE '%free%' AND monthly_price > '0.00' THEN 'free plan with charges'
        WHEN LOWER(TRIM(plan)) LIKE '%basic%' AND monthly_price != '9.99' THEN 'basic plan with wrong amount'
        WHEN LOWER(TRIM(plan)) LIKE '%premium%' AND monthly_price != '19.99' THEN 'premium plan with wrong amount'
        ELSE 'ok'
    END AS quality_flag
FROM subscriptions
WHERE quality_flag != 'ok';


-- ******************************************** Contextual relevance **********************************************
-- ******** Does this row belong in my analysis? - Clean data can still be the wrong data for the question ********

-- Revenue from real customers

SELECT
    *
FROM subscriptions
WHERE COALESCE(customer_email, '') NOT LIKE 'test%';



-- ************************************** Final Cleaning Pipeline ****************************************

DROP TABLE IF EXISTS subscriptions_clean;

CREATE TABLE subscriptions_clean AS

WITH completeness AS (
    SELECT
        subscription_id,
        customer_id,
        customer_email,
        country,
        plan,
        monthly_price,
        status,
        start_date,
        end_date,
        -- payment_method,
        updated_at,
        internal_notes,
        CASE
            WHEN payment_method = 'NULL' OR payment_method = 'N/A' OR payment_method = '' THEN 'Unknown'
            ELSE payment_method
        END AS payment_method
    FROM subscriptions
),

consistency AS (
    SELECT
        subscription_id,
        customer_id,
        LOWER(TRIM(customer_email)) AS customer_email,
        CASE
            WHEN LOWER(country) LIKE '%italy%' OR LOWER(country) LIKE '%it%' THEN 'Italy'
            WHEN LOWER(country) LIKE '%u%' THEN 'United Kingdom'
            WHEN LOWER(country) LIKE '%germany%' OR LOWER(country) LIKE '%de%' THEN 'Germany'
            WHEN LOWER(country) LIKE '%ireland%' or LOWER(country) LIKE '%ie%' THEN 'Ireland'
            ELSE 'Unknown'
        END AS country,
        UPPER(SUBSTR(TRIM(plan), 1, 1)) || LOWER(SUBSTR(TRIM(plan), 2)) AS plan,
        CAST(monthly_price AS REAL) AS monthly_price,
        CASE
            WHEN LOWER(status) LIKE '%active%' THEN 'Active'
            WHEN LOWER(status) LIKE '%cancel%' THEN 'Cancelled'
            WHEN LOWER(status) LIKE '%pause%' THEN 'Paused'
        END AS status,
        CASE
            WHEN start_date LIKE '____-__-__' THEN date(start_date)
            WHEN start_date LIKE '__/__/____' THEN date(
                substr(start_date, 7, 4) || '-' ||
                substr(start_date, 4, 2) || '-' ||
                substr(start_date, 1, 2)
            )
        END AS start_date,
        end_date,
        payment_method,
        updated_at,
        internal_notes
    FROM completeness
),

correctness AS (
    SELECT
        subscription_id,
        customer_id,
        customer_email,
        country,
        plan,
        -- monthly_price,
        status,
        start_date,
        end_date,
        payment_method,
        updated_at,
        internal_notes,
        CASE
            WHEN monthly_price < 0 THEN monthly_price * -1
            WHEN monthly_price > 100 then monthly_price / 100
            ELSE monthly_price
        END AS monthly_price
    FROM consistency
),

ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER(
            PARTITION BY subscription_id
            ORDER BY updated_at DESC
        ) AS row_num
    FROM correctness
),

conformity AS (
    SELECT
        subscription_id,
        customer_id,
        customer_email,
        country,
        plan,
        monthly_price,
        status,
        start_date,
        end_date,
        payment_method,
        updated_at,
        internal_notes
    FROM ranked
    WHERE row_num = 1
),

conherence AS (
    SELECT
        *,
        CASE
            WHEN LOWER(TRIM(status)) LIKE '%active%' AND TRIM(end_date) <> '' THEN 'active with end date'
            WHEN LOWER(TRIM(status)) LIKE '%cancel%' AND TRIM(end_date) = '' THEN 'cancelled with no end date'
            WHEN LOWER(TRIM(plan)) NOT LIKE '%free%' AND monthly_price = '0.00' THEN 'paid plan without charges'
            WHEN LOWER(TRIM(plan)) LIKE '%free%' AND monthly_price > '0.00' THEN 'free plan with charges'
            WHEN LOWER(TRIM(plan)) LIKE '%basic%' AND monthly_price != '9.99' THEN 'basic plan with wrong amount'
            WHEN LOWER(TRIM(plan)) LIKE '%premium%' AND monthly_price != '19.99' THEN 'premium plan with wrong amount'
            ELSE 'ok'
        END AS quality_flag
    FROM conformity
)

-- Contextual relevance
SELECT 
    subscription_id,
        customer_id,
        customer_email,
        country,
        plan,
        monthly_price,
        status,
        start_date,
        end_date,
        payment_method,
        updated_at,
        internal_notes,
        quality_flag
FROM conherence
WHERE COALESCE(customer_email, '') NOT LIKE 'test%';


-- Testing new table

SELECT
    *
FROM subscriptions_clean;