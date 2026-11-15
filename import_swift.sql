-- UMDAC Datathon 2026 | Import the organizer's original Swift CSV
-- In Workbench, place the cursor inside each statement and press Ctrl+Enter.
-- Run the sections in order. Run the LOAD DATA statement once after checking
-- that the destination table is empty.

-- 1. Find the folder MySQL Server is allowed to read.
SHOW VARIABLES LIKE 'secure_file_priv';
-- Extract the organizer's ZIP and copy the original .csv into the returned
-- folder. If the value is blank, use any path readable by the MySQL service.
-- If the value is NULL, server-side file import is disabled on this server.
-- The file path is on the MySQL server's machine. This assumes local MySQL.

-- 2. Create the database and table. Run each statement in this section.
CREATE DATABASE IF NOT EXISTS swift_datathon CHARACTER SET utf8mb4;

CREATE TABLE IF NOT EXISTS swift_datathon.swift_payments (
    disclaimer                 TEXT,
    epoch_seconds              BIGINT,
    currency_code              VARCHAR(12),
    usd_amount                 DECIMAL(24, 6),
    ordering_bic8              VARCHAR(16),
    beneficiary_bic8           VARCHAR(16),
    bic8_path                  TEXT,
    total_duration             BIGINT,
    continuity_qflag           VARCHAR(8),
    currency_conversion_count  INT,
    participant_count          INT,
    transaction_type_code      VARCHAR(32),
    ordering_account           TEXT,
    beneficiary_account        TEXT,
    ordering_details           TEXT,
    ordering_tokens            TEXT,
    beneficiary_details        TEXT,
    beneficiary_tokens         TEXT,
    ordering_type              VARCHAR(8),
    beneficiary_type           VARCHAR(8),
    anomaly_type               VARCHAR(64)
) ENGINE=InnoDB;

-- 3. Check the table before importing.
SELECT COUNT(*) AS existing_rows FROM swift_datathon.swift_payments;
-- 0 rows: proceed to step 4.
-- 10,000,000 rows: skip the import and open currency_use.sql.
-- Any other nonzero count: investigate before retrying. Loading appends rows.

-- 4. EDIT FILE PATH BELOW. Replace the path in single quotes directly after
-- LOAD DATA INFILE with the full path to your copied CSV. Use forward slashes.
-- Keep the parser settings for the original CSV, which has quoted multiline
-- fields and CRLF record endings.
LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/swift_umdac_datathon_2026_fictitious_payment_data.csv'
INTO TABLE swift_datathon.swift_payments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(disclaimer, @epoch, currency_code, @amount,
 ordering_bic8, beneficiary_bic8, bic8_path, @duration,
 continuity_qflag, @conversions, @participants, transaction_type_code,
 ordering_account, beneficiary_account, ordering_details, ordering_tokens,
 beneficiary_details, beneficiary_tokens, ordering_type, beneficiary_type,
 @anomaly)
SET epoch_seconds = NULLIF(@epoch, ''),
    usd_amount = NULLIF(@amount, ''),
    total_duration = NULLIF(@duration, ''),
    currency_conversion_count = NULLIF(@conversions, ''),
    participant_count = NULLIF(@participants, ''),
    anomaly_type = NULLIF(@anomaly, '');

-- 5. Check Action Output for 10,000,000 records, 0 skipped and 0 warnings.
-- If there are warnings, run the next statement immediately.
SHOW WARNINGS LIMIT 10;

SELECT COUNT(*) AS imported_rows FROM swift_datathon.swift_payments;
-- Expected: 10,000,000. Then open currency_use.sql in Workbench.
