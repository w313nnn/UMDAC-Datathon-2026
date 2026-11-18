-- UMDAC Datathon 2026 | Hui Min | routing-analysis
-- Purpose: compare duration across FX counts within each route type and size.
-- Requires MySQL 8.0 and the populated swift_datathon.swift_payments table.
-- Read-only: this script does not create, import or modify data.
-- Reconstructed from the saved CSV columns and documented analysis scope;
-- not rerun against MySQL when this file was prepared.
--
-- Run the SELECT in MySQL Workbench only when fresh results are needed.
-- Export the complete result grid with headers as duration_by_conversions.csv.
-- Saved snapshot: 146 groups totalling 9,232,796 continuous payments.
-- Within each route/participant group, summed payment_count should match
-- duration_by_participants.csv. Keep all groups, not just the plotted segment.
--
-- Scope: continuous paths only (Y); labelled anomalies included.
-- Participant count includes endpoints. Conversion count is the FX-step count.
-- Duration is in seconds. AVG/MIN/MAX exclude NULL durations; COUNT(*) does not.
-- The saved routing summary reports zero missing durations. If that changes,
-- check non-NULL duration counts before weighting or comparing these means.
-- Grouping holds route type and institution count constant; other differences
-- such as currency, corridor and payment amount remain uncontrolled.

SELECT
    transaction_type_code AS route_type,
    participant_count,
    currency_conversion_count AS conversion_count,
    COUNT(*) AS payment_count,
    ROUND(AVG(total_duration), 2) AS average_seconds,
    MIN(total_duration) AS min_seconds,
    MAX(total_duration) AS max_seconds
FROM swift_datathon.swift_payments
WHERE continuity_qflag = 'Y'
GROUP BY transaction_type_code, participant_count, currency_conversion_count
ORDER BY transaction_type_code, participant_count, currency_conversion_count;
