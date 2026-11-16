# How to run our SQL files

Use MySQL 8.0 and open the scripts in MySQL Workbench. The data must already be imported into `swift_datathon.swift_payments`.

1. If the table is missing, read `import_swift.sql` and change its CSV path to the permitted folder on your own computer. Do not import again into an already populated table.
2. Open one analysis script at a time. Run one statement at a time, especially files containing multiple queries.
3. Export the small result table as CSV for Excel. Keep the SQL filename with the results.
4. Use INSIGHTS_LOG.md to understand the results and their limits.

## Files uploaded on 16 November 2026

All SQL filenames referenced in the insights log are now in this branch: 17 SQL files including the two existing import/currency-use files.

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

## Branches

This work was authored by the user, so the scripts and insights log are collected on currency-dashboard, including the exploratory anomaly scripts. Hui Min and Vincent can read/download them from this branch.

The first upload also reached main before the request to use personal branches arrived. Those copies remain on main. Future work should go to the author's branch first.
