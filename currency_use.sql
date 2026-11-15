USE swift_datathon;

-- 1. Compare overall USD use by businesses and consumers.
SELECT
    CASE ordering_type
        WHEN 'B' THEN 'Business'
        WHEN 'C' THEN 'Consumer'
    END AS sender_type,
    COUNT(*) AS payment_count,
    SUM(currency_code = 'USD') AS usd_count,
    ROUND(100.0 * AVG(currency_code = 'USD'), 2) AS usd_share_pct
FROM swift_payments
WHERE ordering_type IN ('B', 'C')
  AND NULLIF(TRIM(currency_code), '') IS NOT NULL
GROUP BY ordering_type
ORDER BY ordering_type;

-- 2. Compare USD use after giving both groups the same sending-bank country mix.
WITH country_counts AS (
    SELECT
        SUBSTRING(ordering_bic8, 5, 2) AS bank_country,
        SUM(ordering_type = 'B') AS business_n,
        SUM(ordering_type = 'C') AS consumer_n,
        SUM(ordering_type = 'B' AND currency_code = 'USD') AS business_usd,
        SUM(ordering_type = 'C' AND currency_code = 'USD') AS consumer_usd
    FROM swift_payments
    WHERE ordering_type IN ('B', 'C')
      AND NULLIF(TRIM(currency_code), '') IS NOT NULL
      AND CHAR_LENGTH(ordering_bic8) = 8
    GROUP BY SUBSTRING(ordering_bic8, 5, 2)
),
eligible AS (
    SELECT *,
           business_n + consumer_n AS country_n
    FROM country_counts
    WHERE business_n > 0 AND consumer_n > 0
)
SELECT
    COUNT(*) AS countries_compared,
    SUM(country_n) AS payments_covered,
    ROUND(100.0 * SUM(country_n * business_usd / business_n)
        / SUM(country_n), 4) AS adjusted_business_usd_pct,
    ROUND(100.0 * SUM(country_n * consumer_usd / consumer_n)
        / SUM(country_n), 4) AS adjusted_consumer_usd_pct,
    ROUND(100.0 * SUM(country_n * (
        business_usd / business_n - consumer_usd / consumer_n
    )) / SUM(country_n), 4) AS adjusted_gap_pp
FROM eligible;

-- 3. Compare USD use by US bank involvement for the Excel chart.
WITH bank_locations AS (
    SELECT
        SUBSTRING(ordering_bic8, 5, 2) = 'US' AS sending_bank_us,
        SUBSTRING(beneficiary_bic8, 5, 2) = 'US' AS receiving_bank_us,
        currency_code = 'USD' AS uses_usd
    FROM swift_payments
    WHERE CHAR_LENGTH(ordering_bic8) = 8
      AND CHAR_LENGTH(beneficiary_bic8) = 8
      AND NULLIF(TRIM(currency_code), '') IS NOT NULL
)
SELECT
    CASE
        WHEN sending_bank_us AND receiving_bank_us THEN 'Both banks in US'
        WHEN sending_bank_us THEN 'Sending bank in US only'
        WHEN receiving_bank_us THEN 'Receiving bank in US only'
        ELSE 'Neither bank in US'
    END AS bank_group,
    COUNT(*) AS payment_count,
    SUM(uses_usd) AS usd_count,
    ROUND(100.0 * SUM(uses_usd) / COUNT(*), 2) AS usd_share_pct
FROM bank_locations
GROUP BY sending_bank_us, receiving_bank_us
ORDER BY sending_bank_us, receiving_bank_us;
