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