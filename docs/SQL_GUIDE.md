# How to run our SQL files

Use MySQL 8.0 and open the scripts in MySQL Workbench. The data must already be imported into `swift_datathon.swift_payments`.

1. If the table is missing, read [import_swift.sql](../sql/import_swift.sql) and change its CSV path to the permitted folder on your own computer. Do not import again into an already populated table.
2. Open one analysis script at a time. Run one statement at a time, especially files containing multiple queries.
3. Export the small result table as CSV for Excel. Keep the SQL filename with the results.
4. Use [INSIGHTS_LOG.md](INSIGHTS_LOG.md) to understand the results and their limits.

## Files uploaded on 16 November 2026

The 16 November collection contained 17 SQL files, including the import and currency-use scripts. The scripts for all three workstreams are now in the [sql folder](../sql/).

The local file named currency_receiving_country.sql actually contained the Singapore version. In GitHub:
- currency_receiving_country.sql is the GB-origin comparison reconstructed from the original query.
- currency_receiving_country_sg.sql is the corrected Singapore-origin comparison (SGD currency, SG country).

The uploaded payment_amount_profile.sql removes an accidental `3333` after payments_with_amount. The desktop copies were not changed. Download these corrected versions when continuing locally.

The scripts were reviewed against the queries and results in our chat. They were not rerun against MySQL during upload.

## Runtime and output

- Most grouped scans previously took about 40–100 seconds on the original laptop; your timings may differ.
- Exact percentile scripts sort many records and may take several minutes.
- The SECOND statement in payment_amount_anomaly_check.sql previously took about 59 minutes. Reuse saved results when possible.
- romance_labels_by_country_pair.sql returned 31,235 rows. Use romance_top_country_pairs.sql for a 30-row view.
- Analysis scripts read the data; import_swift.sql creates/imports data.
