-- MySQL 8. Run ONE numbered query at a time; export each Result Grid as CSV.
-- Full-table scans can still take time. LIMIT does not limit scan work.
USE swift_datathon;

-- Shared convention: trim ASCII spaces; NULL, blank and literal 'None'
-- (case-insensitive) mean unlabelled. Other labels are upper-case.
-- CUSTOMER_RECALL is retained as a supplied label; FAQ scope remains unresolved.

-- 1. Export as label_profile.csv. Both value denominators are explicit.
WITH grouped AS (
 SELECT CASE WHEN anomaly_type IS NULL OR TRIM(anomaly_type) = ''
                  OR UPPER(TRIM(anomaly_type)) = 'NONE' THEN 'None'
             ELSE UPPER(TRIM(anomaly_type)) END AS anomaly_type,
        COUNT(*) AS payment_count,
        SUM(usd_amount) AS usd_amount
 FROM swift_payments
 GROUP BY 1
)
SELECT anomaly_type, payment_count,
 ROUND(100.0 * payment_count / SUM(payment_count) OVER (), 5) AS payment_share_pct,
 ROUND(usd_amount, 2) AS usd_amount,
 ROUND(100.0 * usd_amount / NULLIF(SUM(usd_amount) OVER (), 0), 5)
     AS share_of_all_payment_value_pct,
 CASE WHEN anomaly_type = 'None' THEN NULL ELSE
 ROUND(100.0 * usd_amount / NULLIF(SUM(CASE WHEN anomaly_type <> 'None'
                    THEN usd_amount ELSE 0 END) OVER (), 0), 5)
 END AS share_of_labelled_payment_value_pct
FROM grouped ORDER BY payment_count DESC, anomaly_type;

-- 2. Export as party_pair_profile.csv. Denominator = all B/C payments in each pair.
WITH cleaned AS (
 SELECT ordering_type, beneficiary_type, usd_amount,
 CASE WHEN anomaly_type IS NULL OR TRIM(anomaly_type) = ''
                  OR UPPER(TRIM(anomaly_type)) = 'NONE' THEN 0 ELSE 1 END AS labelled
 FROM swift_payments
 WHERE ordering_type IN ('B', 'C') AND beneficiary_type IN ('B', 'C')
)
SELECT CONCAT(ordering_type, '->', beneficiary_type) AS party_pair,
 COUNT(*) AS payment_count, SUM(labelled) AS labelled_payment_count,
 ROUND(100.0 * SUM(labelled) / COUNT(*), 5) AS labelled_rate_pct,
 ROUND(SUM(CASE WHEN labelled = 1 THEN usd_amount ELSE 0 END), 2) AS labelled_usd_amount
FROM cleaned GROUP BY ordering_type, beneficiary_type ORDER BY party_pair;

-- 3. Export as party_pair_labels.csv. Includes unlabelled rows for reconciliation.
-- Each label rate uses ALL payments in that party pair, not just labelled rows.
WITH grouped AS (
 SELECT CONCAT(ordering_type, '->', beneficiary_type) AS party_pair,
 CASE WHEN anomaly_type IS NULL OR TRIM(anomaly_type) = ''
                  OR UPPER(TRIM(anomaly_type)) = 'NONE' THEN 'None'
             ELSE UPPER(TRIM(anomaly_type)) END AS anomaly_type,
 COUNT(*) AS payment_count, SUM(usd_amount) AS usd_amount
 FROM swift_payments
 WHERE ordering_type IN ('B', 'C') AND beneficiary_type IN ('B', 'C')
 GROUP BY 1, 2
)
SELECT party_pair, anomaly_type, payment_count,
 SUM(payment_count) OVER (PARTITION BY party_pair) AS pair_payment_count,
 ROUND(100.0 * payment_count /
       SUM(payment_count) OVER (PARTITION BY party_pair), 5) AS label_rate_pct,
 ROUND(usd_amount, 2) AS usd_amount
FROM grouped ORDER BY party_pair, anomaly_type;

-- 4. OPTIONAL: one account's history. Choose a nonblank account from Python's
-- account_label_history.csv. Set role to exactly Ordering or Beneficiary.
-- This avoids grouping all 20 million account appearances; it still scans data.
SET @account_role = 'Beneficiary';
SET @account_id = NULL; -- CHANGE THIS: e.g. 'synthetic-account-id'
WITH history AS (
 SELECT CASE WHEN anomaly_type IS NULL OR TRIM(anomaly_type) = ''
                  OR UPPER(TRIM(anomaly_type)) = 'NONE' THEN 'None'
             ELSE UPPER(TRIM(anomaly_type)) END AS anomaly_type, usd_amount
 FROM swift_payments
 WHERE @account_id IS NOT NULL AND TRIM(@account_id) <> ''
 AND ((@account_role = 'Ordering' AND ordering_account = @account_id)
   OR (@account_role = 'Beneficiary' AND beneficiary_account = @account_id))
)
SELECT anomaly_type, COUNT(*) AS payment_count,
 SUM(COUNT(*)) OVER () AS account_payment_count,
 ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 5) AS label_rate_pct,
 ROUND(SUM(usd_amount), 2) AS usd_amount
FROM history GROUP BY anomaly_type ORDER BY payment_count DESC, anomaly_type;

-- 5. OPTIONAL: matching payments for ONE chosen account pair.
-- Repeated values can be legitimate. Check elapsed time and supplied labels.
-- Intentionally no automatic full-file duplicate GROUP BY.
SET @ordering_account = NULL;    -- CHANGE THIS to a quoted account ID
SET @beneficiary_account = NULL; -- CHANGE THIS to a quoted account ID
SELECT epoch_seconds, currency_code, usd_amount, anomaly_type
FROM swift_payments
WHERE @ordering_account IS NOT NULL AND TRIM(@ordering_account) <> ''
  AND @beneficiary_account IS NOT NULL AND TRIM(@beneficiary_account) <> ''
  AND ordering_account = @ordering_account
  AND beneficiary_account = @beneficiary_account
ORDER BY epoch_seconds, currency_code, usd_amount
LIMIT 200;
-- This returns a capped inspection sample, not a count of all duplicates.
