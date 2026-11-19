-- Check currency use separately for business and consumer senders.
-- Compare SG → CN with SG → SG.

SELECT
    SUBSTRING(beneficiary_bic8, 5, 2) AS receiving_country,

    CASE ordering_type
        WHEN 'B' THEN 'Business'
        WHEN 'C' THEN 'Consumer'
    END AS sender_type,

    COUNT(*) AS payment_count,

    SUM(currency_code = 'CNY') AS cny_payment_count,

    ROUND(
        100.0 * AVG(currency_code = 'CNY'), 2
    ) AS cny_share_pct,

    ROUND(
        100.0 * AVG(currency_code = 'SGD'), 2
    ) AS sgd_share_pct,

    ROUND(
        100.0 * AVG(currency_code = 'EUR'), 2
    ) AS eur_share_pct,

    ROUND(
        100.0 * AVG(currency_code = 'USD'), 2
    ) AS usd_share_pct,

    ROUND(
        100.0 * AVG(
            currency_code NOT IN ('CNY', 'SGD', 'EUR', 'USD')
        ), 2
    ) AS other_currency_share_pct

FROM swift_datathon.swift_payments

WHERE CHAR_LENGTH(ordering_bic8) = 8
  AND CHAR_LENGTH(beneficiary_bic8) = 8
  AND SUBSTRING(ordering_bic8, 5, 2) = 'SG'
  AND SUBSTRING(beneficiary_bic8, 5, 2) IN ('CN', 'SG')
  AND ordering_type IN ('B', 'C')
  AND NULLIF(TRIM(currency_code), '') IS NOT NULL

GROUP BY
    SUBSTRING(beneficiary_bic8, 5, 2),
    ordering_type

ORDER BY receiving_country, sender_type;