-- Explore romance-scam labels among consumer-origin payments.
-- Comparison group includes all payments without this specific label.
-- No window functions or payment-level sorting.

SELECT
    beneficiary_type AS recipient_type_code,

    CASE
        WHEN usd_amount IS NULL THEN '0. Missing'
        WHEN usd_amount <= 0 THEN '1. Zero or negative'
        WHEN usd_amount < 100 THEN '2. Under $100'
        WHEN usd_amount < 1000 THEN '3. $100 to under $1,000'
        WHEN usd_amount < 10000 THEN '4. $1,000 to under $10,000'
        WHEN usd_amount < 100000 THEN '5. $10,000 to under $100,000'
        ELSE '6. $100,000 or more'
    END AS amount_band,

    CASE
        WHEN ordering_bic8 IS NULL
          OR beneficiary_bic8 IS NULL
          OR CHAR_LENGTH(ordering_bic8) <> 8
          OR CHAR_LENGTH(beneficiary_bic8) <> 8
            THEN 'Unknown'
        WHEN SUBSTRING(ordering_bic8, 5, 2)
           = SUBSTRING(beneficiary_bic8, 5, 2)
            THEN 'Same bank-country'
        ELSE 'Different bank-countries'
    END AS bank_country_relationship,

    COUNT(*) AS total_payments,

    SUM(
        CASE WHEN TRIM(anomaly_type) = 'ROMANCE_SCAM'
             THEN 1 ELSE 0 END
    ) AS romance_label_count,

    SUM(
        CASE WHEN TRIM(anomaly_type) = 'ROMANCE_SCAM'
             THEN 0 ELSE 1 END
    ) AS other_payment_count,

    ROUND(
        10000.0 * SUM(
            CASE WHEN TRIM(anomaly_type) = 'ROMANCE_SCAM'
                 THEN 1 ELSE 0 END
        ) / COUNT(*),
        2
    ) AS romance_labels_per_10000

FROM swift_datathon.swift_payments

WHERE ordering_type = 'C'

GROUP BY
    beneficiary_type,
    amount_band,
    bank_country_relationship

ORDER BY
    beneficiary_type,
    amount_band,
    bank_country_relationship;