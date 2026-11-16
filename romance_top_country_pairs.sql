-- Top 30 bank-country pairs by romance-scam label count.
-- Consumer senders; both recipient types combined.

WITH payment_groups AS (
    SELECT
        CASE
            WHEN ordering_bic8 IS NULL
              OR CHAR_LENGTH(TRIM(ordering_bic8)) <> 8
                THEN '[UNKNOWN]'
            ELSE UPPER(SUBSTRING(TRIM(ordering_bic8), 5, 2))
        END AS sending_country,

        CASE
            WHEN beneficiary_bic8 IS NULL
              OR CHAR_LENGTH(TRIM(beneficiary_bic8)) <> 8
                THEN '[UNKNOWN]'
            ELSE UPPER(SUBSTRING(TRIM(beneficiary_bic8), 5, 2))
        END AS receiving_country,

        CASE
            WHEN TRIM(anomaly_type) = 'ROMANCE_SCAM'
                THEN 1
            ELSE 0
        END AS has_romance_label

    FROM swift_datathon.swift_payments
    WHERE ordering_type = 'C'
)
SELECT
    sending_country,
    receiving_country,
    COUNT(*) AS total_payments,
    SUM(has_romance_label) AS romance_label_count,

    ROUND(
        10000.0 * SUM(has_romance_label) / COUNT(*),
        2
    ) AS romance_labels_per_10000

FROM payment_groups

GROUP BY sending_country, receiving_country

HAVING SUM(has_romance_label) > 0

ORDER BY
    romance_label_count DESC,
    total_payments DESC,
    sending_country,
    receiving_country

LIMIT 30;