-- Inspect labels before deciding which mean anomalous or normal.
SELECT
    CASE
        WHEN anomaly_type IS NULL THEN '[NULL]'
        WHEN TRIM(anomaly_type) = '' THEN '[BLANK]'
        ELSE TRIM(anomaly_type)
    END AS anomaly_label,
    COUNT(*) AS payment_count

FROM swift_datathon.swift_payments

GROUP BY
    CASE
        WHEN anomaly_type IS NULL THEN '[NULL]'
        WHEN TRIM(anomaly_type) = '' THEN '[BLANK]'
        ELSE TRIM(anomaly_type)
    END

ORDER BY payment_count DESC;

-- Exploratory definition:
-- exceptionally large = amount at or above each customer group's P99.
-- P99 uses the nearest-rank method.
-- Ties at the threshold can make the large group exceed 1%.

WITH ranked_payments AS (
    SELECT
        ordering_type,
        beneficiary_type,
        usd_amount,

        CASE
            WHEN anomaly_type IS NULL THEN '[NULL]'
            WHEN TRIM(anomaly_type) = '' THEN '[BLANK]'
            ELSE TRIM(anomaly_type)
        END AS anomaly_label,

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
),
with_threshold AS (
    SELECT
        ordering_type,
        beneficiary_type,
        usd_amount,
        anomaly_label,

        MAX(
            CASE
                WHEN row_num = CEIL(0.99 * group_count)
                THEN usd_amount
            END
        ) OVER (
            PARTITION BY ordering_type, beneficiary_type
        ) AS p99_threshold

    FROM ranked_payments
),
label_counts AS (
    SELECT
        ordering_type,
        beneficiary_type,
        p99_threshold,

        CASE
            WHEN usd_amount >= p99_threshold
                THEN 'At or above P99'
            ELSE 'Below P99'
        END AS amount_band,

        anomaly_label,
        COUNT(*) AS label_payment_count

    FROM with_threshold

    GROUP BY
        ordering_type,
        beneficiary_type,
        p99_threshold,
        amount_band,
        anomaly_label
)
SELECT
    ordering_type AS sender_type_code,
    beneficiary_type AS recipient_type_code,
    p99_threshold AS p99_threshold_usd,
    amount_band,
    anomaly_label,
    label_payment_count,

    SUM(label_payment_count) OVER (
        PARTITION BY
            ordering_type,
            beneficiary_type,
            amount_band
    ) AS band_payment_count,

    ROUND(
        100.0 * label_payment_count
        / SUM(label_payment_count) OVER (
            PARTITION BY
                ordering_type,
                beneficiary_type,
                amount_band
        ),
        4
    ) AS label_share_pct

FROM label_counts

ORDER BY
    ordering_type,
    beneficiary_type,
    anomaly_label,
    amount_band;