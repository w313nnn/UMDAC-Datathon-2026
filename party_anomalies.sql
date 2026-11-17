-- UMDAC Datathon 2026 | Vincent: party behaviour and labelled anomalies
-- Requires the 10,000,000-row swift_datathon.swift_payments table.
USE swift_datathon;

-- 1. Label prevalence and USD exposure. Blank labels are treated as unlabeled.
SELECT
    COALESCE(NULLIF(TRIM(anomaly_type), ''), 'None') AS anomaly_type,
    COUNT(*) AS payment_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 4) AS payment_share_pct,
    ROUND(SUM(usd_amount), 2) AS usd_amount,
    ROUND(100.0 * SUM(usd_amount) / SUM(SUM(usd_amount)) OVER (), 4) AS value_share_pct,
    ROUND(AVG(usd_amount), 2) AS mean_usd_amount
FROM swift_payments
GROUP BY COALESCE(NULLIF(TRIM(anomaly_type), ''), 'None')
ORDER BY payment_count DESC;

-- 2. Party-pair exposure. B = business and C = consumer.
-- Compare rates within party pairs, not raw anomaly counts alone.
SELECT
    CONCAT(ordering_type, '->', beneficiary_type) AS party_pair,
    COUNT(*) AS payment_count,
    SUM(COALESCE(NULLIF(TRIM(anomaly_type), ''), 'None') <> 'None') AS labelled_anomaly_count,
    ROUND(100.0 * AVG(COALESCE(NULLIF(TRIM(anomaly_type), ''), 'None') <> 'None'), 4) AS labelled_anomaly_rate_pct,
    ROUND(SUM(CASE WHEN COALESCE(NULLIF(TRIM(anomaly_type), ''), 'None') <> 'None' THEN usd_amount ELSE 0 END), 2) AS labelled_usd_amount
FROM swift_payments
WHERE ordering_type IN ('B', 'C') AND beneficiary_type IN ('B', 'C')
GROUP BY ordering_type, beneficiary_type
ORDER BY labelled_anomaly_rate_pct DESC, payment_count DESC;

-- 3. Party pair by anomaly label. This shows which labelled behaviour occurs
-- in which payment relationship; retain the denominator from query 2.
SELECT
    CONCAT(ordering_type, '->', beneficiary_type) AS party_pair,
    COALESCE(NULLIF(TRIM(anomaly_type), ''), 'None') AS anomaly_type,
    COUNT(*) AS payment_count,
    ROUND(SUM(usd_amount), 2) AS usd_amount,
    ROUND(AVG(total_duration), 2) AS mean_duration_seconds
FROM swift_payments
WHERE ordering_type IN ('B', 'C') AND beneficiary_type IN ('B', 'C')
  AND COALESCE(NULLIF(TRIM(anomaly_type), ''), 'None') <> 'None'
GROUP BY ordering_type, beneficiary_type, COALESCE(NULLIF(TRIM(anomaly_type), ''), 'None')
ORDER BY anomaly_type, payment_count DESC;

-- 4. Account concentration. Synthetic account IDs may repeat. This query
-- identifies accounts appearing in labelled payments and gives each account's
-- complete payment history in this file. Do not identify real customers.
WITH labelled_accounts AS (
    SELECT 'Ordering' AS account_role, ordering_account AS account, anomaly_type
    FROM swift_payments
    WHERE NULLIF(TRIM(anomaly_type), '') IS NOT NULL
    UNION ALL
    SELECT 'Beneficiary', beneficiary_account, anomaly_type
    FROM swift_payments
    WHERE NULLIF(TRIM(anomaly_type), '') IS NOT NULL
),
all_accounts AS (
    SELECT 'Ordering' AS account_role, ordering_account AS account, usd_amount
    FROM swift_payments
    UNION ALL
    SELECT 'Beneficiary', beneficiary_account, usd_amount
    FROM swift_payments
)
SELECT
    l.account_role,
    l.account,
    l.anomaly_type,
    COUNT(*) AS labelled_payment_count,
    a.all_payment_count,
    ROUND(a.all_usd_amount, 2) AS all_usd_amount
FROM labelled_accounts l
JOIN (
    SELECT account_role, account, COUNT(*) AS all_payment_count, SUM(usd_amount) AS all_usd_amount
    FROM all_accounts
    GROUP BY account_role, account
) a ON a.account_role = l.account_role AND a.account = l.account
GROUP BY l.account_role, l.account, l.anomaly_type, a.all_payment_count, a.all_usd_amount
ORDER BY labelled_payment_count DESC, all_usd_amount DESC
LIMIT 50;

-- 5. Candidate duplicate-payment investigation. This does not prove a duplicate:
-- it flags records sharing source account, beneficiary account, currency and value.
SELECT
    ordering_account,
    beneficiary_account,
    currency_code,
    usd_amount,
    COUNT(*) AS matching_payment_count,
    MIN(epoch_seconds) AS first_epoch,
    MAX(epoch_seconds) AS last_epoch,
    SUM(COALESCE(NULLIF(TRIM(anomaly_type), ''), 'None') = 'DUPLICATE_PAYMENT') AS supplied_duplicate_labels
FROM swift_payments
GROUP BY ordering_account, beneficiary_account, currency_code, usd_amount
HAVING COUNT(*) > 1
ORDER BY matching_payment_count DESC, supplied_duplicate_labels DESC
LIMIT 100;
