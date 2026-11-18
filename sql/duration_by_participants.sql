-- Purpose: compare duration by route type and number of institutions.
-- Requires MySQL 8.0 and the populated swift_datathon.swift_payments table.
-- Read-only: this script does not create, import or modify data.
-- Reconstructed from the saved CSV columns and documented analysis scope;
-- not rerun against MySQL when this file was prepared.
--
-- Run the SELECT in MySQL Workbench only when fresh results are needed.
-- Export the complete result grid with headers as duration_by_participants.csv.
-- Saved snapshot: 29 groups totalling 9,232,796 continuous payments.
-- The sum of payment_count should match the Y rows in routing_summary.csv.
--
-- Scope: continuous paths only (Y); labelled anomalies included.
-- Participant count includes endpoint institutions, not just intermediaries.
-- Retain all route sizes, including rare sizes above 7 and any NULL group.
-- Duration is in seconds. AVG/MIN/MAX exclude NULL durations.
-- payment_count - durations_available gives missing durations in each group.

SELECT
    transaction_type_code AS route_type,
    participant_count,
    COUNT(*) AS payment_count,
    COUNT(total_duration) AS durations_available,
    ROUND(AVG(total_duration), 2) AS average_seconds,
    MIN(total_duration) AS min_seconds,
    MAX(total_duration) AS max_seconds
FROM swift_datathon.swift_payments
WHERE continuity_qflag = 'Y'
GROUP BY transaction_type_code, participant_count
ORDER BY transaction_type_code, participant_count;
