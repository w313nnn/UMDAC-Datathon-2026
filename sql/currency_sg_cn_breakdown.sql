-- Compare every currency used for SG → CN and SG → SG payments.

WITH currency_counts AS (
    SELECT
        SUBSTRING(beneficiary_bic8, 5, 2) AS receiving_country,
        currency_code,
        COUNT(*) AS payment_count
    FROM swift_datathon.swift_payments
    WHERE CHAR_LENGTH(ordering_bic8) = 8
      AND CHAR_LENGTH(beneficiary_bic8) = 8
      AND SUBSTRING(ordering_bic8, 5, 2) = 'SG'
      AND SUBSTRING(beneficiary_bic8, 5, 2) IN ('CN', 'SG')
      AND NULLIF(TRIM(currency_code), '') IS NOT NULL
    GROUP BY
        SUBSTRING(beneficiary_bic8, 5, 2),
        currency_code
),
currency_shares AS (
    SELECT
        receiving_country,
        currency_code,
        payment_count,
        SUM(payment_count) OVER (
            PARTITION BY receiving_country
        ) AS corridor_total
    FROM currency_counts
)
SELECT
    receiving_country,
    currency_code,
    payment_count,
    corridor_total,
    ROUND(
        100.0 * payment_count / corridor_total,
        2
    ) AS currency_share_pct
FROM currency_shares
ORDER BY receiving_country, payment_count DESC, currency_code;