-- UMDAC Datathon 2026 | Hui Min | routing-analysis
-- Purpose: compare route types and path continuity across all payments.
-- Requires MySQL 8.0 and the populated swift_datathon.swift_payments table.
-- Read-only: this script does not create, import or modify data.
-- Query recovered from the analysis section of the local import_swift.sql.
--
-- Run the SELECT in MySQL Workbench only when fresh results are needed.
-- Export the complete result grid with headers as routing_summary.csv.
-- Saved snapshot: 6 groups, 10,000,000 payments, zero missing durations.
-- These are comparison values, not filters or enforced assumptions.
--
-- Scope: all route types and continuity flags; labelled anomalies included.
-- Y means a continuous path; N means a gap, not a failed-payment label.
-- Duration is in seconds. AVG/MIN/MAX exclude NULL durations; payment_count
-- includes them, while missing_duration reports their number explicitly.

SELECT
    transaction_type_code AS route_type,
    continuity_qflag AS continuous_path,
    COUNT(*) AS payment_count,
    COUNT(*) - COUNT(total_duration) AS missing_duration,
    MIN(total_duration) AS min_seconds,
    ROUND(AVG(total_duration), 2) AS average_seconds,
    MAX(total_duration) AS max_seconds
FROM swift_datathon.swift_payments
GROUP BY transaction_type_code, continuity_qflag
ORDER BY transaction_type_code, continuity_qflag;
