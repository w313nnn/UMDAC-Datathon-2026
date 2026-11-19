-- For payments sent from Singapore banks:
-- Does currency use change with the receiving bank's country?

SELECT
    SUBSTRING(beneficiary_bic8, 5, 2) AS receiving_country,
    COUNT(*) AS payment_count,

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
            currency_code NOT IN ('SGD', 'EUR', 'USD')
        ), 2
    ) AS other_currency_share_pct

FROM swift_datathon.swift_payments

WHERE CHAR_LENGTH(ordering_bic8) = 8
  AND CHAR_LENGTH(beneficiary_bic8) = 8
  AND SUBSTRING(ordering_bic8, 5, 2) = 'SG'
  AND NULLIF(TRIM(currency_code), '') IS NOT NULL

GROUP BY SUBSTRING(beneficiary_bic8, 5, 2)

HAVING COUNT(*) >= 1000

ORDER BY payment_count DESC, receiving_country;