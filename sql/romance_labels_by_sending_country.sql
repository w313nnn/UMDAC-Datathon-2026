-- Romance-scam label rates by sending-bank country and recipient type.
-- All amounts included; no minimum group-size filter.
-- One grouped scan; no window functions.

SELECT
    CASE
        WHEN ordering_bic8 IS NULL
          OR CHAR_LENGTH(TRIM(ordering_bic8)) <> 8
            THEN '[UNKNOWN]'
        ELSE UPPER(SUBSTRING(TRIM(ordering_bic8), 5, 2))
    END AS sending_country,

    CASE beneficiary_type
        WHEN 'B' THEN 'Business'
        WHEN 'C' THEN 'Consumer'
        ELSE 'Unknown'
    END AS recipient_type,

    COUNT(*) AS total_payments,

    SUM(
        CASE
            WHEN TRIM(anomaly_type) = 'ROMANCE_SCAM'
                THEN 1
            ELSE 0
        END
    ) AS romance_label_count,

    SUM(
        CASE
            WHEN TRIM(anomaly_type) = 'ROMANCE_SCAM'
                THEN 0
            ELSE 1
        END
    ) AS other_payment_count,

    ROUND(
        10000.0 * SUM(
            CASE
                WHEN TRIM(anomaly_type) = 'ROMANCE_SCAM'
                    THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS romance_labels_per_10000

FROM swift_datathon.swift_payments

WHERE ordering_type = 'C'

GROUP BY
    sending_country,
    recipient_type

ORDER BY
    romance_label_count DESC,
    total_payments DESC,
    sending_country,
    recipient_type;