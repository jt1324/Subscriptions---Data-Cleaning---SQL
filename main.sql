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
    COUNT(DISTINCT subscription_id) AS Qty
FROM status_ok
GROUP BY 1;
