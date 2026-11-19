-- Find the three most-used currencies for each sending-bank country.
WITH currency_counts AS (
    SELECT
        SUBSTRING(ordering_bic8, 5, 2) AS sending_country,
        currency_code,
        COUNT(*) AS payment_count
    FROM swift_datathon.swift_payments
    WHERE CHAR_LENGTH(ordering_bic8) = 8
      AND NULLIF(TRIM(currency_code), '') IS NOT NULL
    GROUP BY
        SUBSTRING(ordering_bic8, 5, 2),
        currency_code
),
ranked_currencies AS (
    SELECT
        sending_country,
        currency_code,
        payment_count,
        SUM(payment_count) OVER (
            PARTITION BY sending_country
        ) AS country_total,
        ROW_NUMBER() OVER (
            PARTITION BY sending_country
            ORDER BY payment_count DESC, currency_code
        ) AS currency_rank
    FROM currency_counts
)
SELECT
    sending_country,
    currency_rank,
    currency_code,
    payment_count,
    country_total,
    ROUND(
        100.0 * payment_count / country_total,
        2
    ) AS currency_share_pct
FROM ranked_currencies
WHERE currency_rank <= 3
  AND country_total >= 10000
ORDER BY country_total DESC, sending_country, currency_rank;