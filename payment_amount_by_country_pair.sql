-- Compare customer-type groups within fixed bank-country pairs.
-- Amounts are expressed in USD.
-- Median: average of middle values.
-- P90: nearest-rank 90th percentile.

WITH base AS (
    SELECT
        SUBSTRING(ordering_bic8, 5, 2) AS sending_country,
        SUBSTRING(beneficiary_bic8, 5, 2) AS receiving_country,
        ordering_type,
        beneficiary_type,
        usd_amount

    FROM swift_datathon.swift_payments

    WHERE CHAR_LENGTH(ordering_bic8) = 8
      AND CHAR_LENGTH(beneficiary_bic8) = 8
      AND ordering_type IN ('B', 'C')
      AND beneficiary_type IN ('B', 'C')
      AND usd_amount > 0

      AND (
          (
              SUBSTRING(ordering_bic8, 5, 2) = 'SG'
              AND SUBSTRING(beneficiary_bic8, 5, 2)
                  IN ('US', 'CN', 'SG')
          )
          OR (
              SUBSTRING(ordering_bic8, 5, 2) = 'GB'
              AND SUBSTRING(beneficiary_bic8, 5, 2)
                  IN ('US', 'GB')
          )
          OR (
              SUBSTRING(ordering_bic8, 5, 2) = 'US'
              AND SUBSTRING(beneficiary_bic8, 5, 2) = 'US'
          )
      )
),
ranked_amounts AS (
    SELECT
        sending_country,
        receiving_country,
        ordering_type,
        beneficiary_type,
        usd_amount,

        ROW_NUMBER() OVER (
            PARTITION BY
                sending_country,
                receiving_country,
                ordering_type,
                beneficiary_type
            ORDER BY usd_amount
        ) AS row_num,

        COUNT(*) OVER (
            PARTITION BY
                sending_country,
                receiving_country,
                ordering_type,
                beneficiary_type
        ) AS group_count

    FROM base
)
SELECT
    sending_country,
    receiving_country,

    CASE ordering_type
        WHEN 'B' THEN 'Business'
        WHEN 'C' THEN 'Consumer'
    END AS sender_type,

    CASE beneficiary_type
        WHEN 'B' THEN 'Business'
        WHEN 'C' THEN 'Consumer'
    END AS recipient_type,

    MAX(group_count) AS payment_count,

    ROUND(AVG(usd_amount), 2) AS average_usd_amount,

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

GROUP BY
    sending_country,
    receiving_country,
    ordering_type,
    beneficiary_type

ORDER BY
    sending_country,
    receiving_country,
    ordering_type,
    beneficiary_type;