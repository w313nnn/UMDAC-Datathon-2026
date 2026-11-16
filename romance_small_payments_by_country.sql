-- Check the small-payment pattern within sending-bank countries.
-- Consumer senders only.
-- One grouped scan; no window functions or payment-level sorting.

WITH country_counts AS (
    SELECT
        SUBSTRING(ordering_bic8, 5, 2) AS sending_country,
        beneficiary_type AS recipient_type_code,

        CASE
            WHEN SUBSTRING(ordering_bic8, 5, 2)
               = SUBSTRING(beneficiary_bic8, 5, 2)
                THEN 'Same bank-country'
            ELSE 'Different bank-countries'
        END AS bank_country_relationship,

        SUM(
            CASE WHEN usd_amount < 100
                 THEN 1 ELSE 0 END
        ) AS small_payment_count,

        SUM(
            CASE WHEN usd_amount < 100
                   AND TRIM(anomaly_type) = 'ROMANCE_SCAM'
                 THEN 1 ELSE 0 END
        ) AS small_romance_count,

        SUM(
            CASE WHEN usd_amount >= 100
                 THEN 1 ELSE 0 END
        ) AS larger_payment_count,

        SUM(
            CASE WHEN usd_amount >= 100
                   AND TRIM(anomaly_type) = 'ROMANCE_SCAM'
                 THEN 1 ELSE 0 END
        ) AS larger_romance_count

    FROM swift_datathon.swift_payments

    WHERE ordering_type = 'C'
      AND beneficiary_type IN ('B', 'C')
      AND usd_amount > 0
      AND CHAR_LENGTH(ordering_bic8) = 8
      AND CHAR_LENGTH(beneficiary_bic8) = 8

    GROUP BY
        SUBSTRING(ordering_bic8, 5, 2),
        beneficiary_type,
        bank_country_relationship
)
SELECT
    sending_country,
    recipient_type_code,
    bank_country_relationship,

    small_payment_count,
    small_romance_count,

    ROUND(
        10000.0 * small_romance_count
        / NULLIF(small_payment_count, 0),
        2
    ) AS small_labels_per_10000,

    larger_payment_count,
    larger_romance_count,

    ROUND(
        10000.0 * larger_romance_count
        / NULLIF(larger_payment_count, 0),
        2
    ) AS larger_labels_per_10000,

    ROUND(
        10000.0 * (
            small_romance_count
                / NULLIF(small_payment_count, 0)
            - larger_romance_count
                / NULLIF(larger_payment_count, 0)
        ),
        2
    ) AS rate_gap_per_10000

FROM country_counts

-- Display groups with enough payments on both sides.
-- This is a readability filter, not a statistical guarantee.
WHERE small_payment_count >= 1000
  AND larger_payment_count >= 1000

ORDER BY
    sending_country,
    recipient_type_code,
    bank_country_relationship;