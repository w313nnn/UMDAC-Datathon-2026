-- First inspection of payment amounts by sender and recipient type.
-- Retain all type values so unexpected categories remain visible.

SELECT
    ordering_type AS sender_type_code,
    beneficiary_type AS recipient_type_code,

    COUNT(*) AS payment_count,
    COUNT(usd_amount) AS payments_with_amount,
    SUM(usd_amount IS NULL) AS missing_amount_count,
    SUM(CASE WHEN usd_amount = 0 THEN 1 ELSE 0 END)
        AS zero_amount_count,
    SUM(CASE WHEN usd_amount < 0 THEN 1 ELSE 0 END)
        AS negative_amount_count,

    MIN(usd_amount) AS minimum_usd_amount,
    ROUND(AVG(usd_amount), 2) AS average_usd_amount,
    MAX(usd_amount) AS maximum_usd_amount

FROM swift_datathon.swift_payments

GROUP BY ordering_type, beneficiary_type

ORDER BY payment_count DESC;