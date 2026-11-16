-- Exact median and nearest-rank P90 by sender/recipient type.
-- Positive, non-missing amounts only.

WITH ranked_amounts AS (
    SELECT
        ordering_type,
        beneficiary_type,
        usd_amount,

        ROW_NUMBER() OVER (
            PARTITION BY ordering_type, beneficiary_type
            ORDER BY usd_amount
        ) AS row_num,

        COUNT(*) OVER (
            PARTITION BY ordering_type, beneficiary_type
        ) AS group_count

    FROM swift_datathon.swift_payments

    WHERE usd_amount > 0
      AND ordering_type IN ('B', 'C')
      AND beneficiary_type IN ('B', 'C')
)

SELECT
    ordering_type AS sender_type_code,
    beneficiary_type AS recipient_type_code,
    MAX(group_count) AS payment_count,

    ROUND(
        AVG(
            CASE
                WHEN row_num IN (
                    (group_count + 1) DIV 2,
                    (group_count + 2) DIV 2
                )
                THEN usd_amount
            END
        ), 2
    ) AS median_usd_amount,

    MAX(
        CASE
            WHEN row_num = CEIL(0.90 * group_count)
            THEN usd_amount
        END
    ) AS p90_usd_amount

FROM ranked_amounts

GROUP BY ordering_type, beneficiary_type

ORDER BY ordering_type, beneficiary_type;