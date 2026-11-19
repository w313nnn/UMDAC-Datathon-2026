# Vincent's findings: customer groups and supplied anomaly labels

## 1. What this work covers

We are looking for rules that may have generated the fictitious Swift payments. B means business and C means consumer. These are payment counts, not counts of different people.

[party_anomalies.sql](../sql/party_anomalies.sql) contains MySQL 8 queries. [analyze_party_anomalies.py](../scripts/analyze_party_anomalies.py) reads the original CSV without loading the whole file into memory. The scripts treat NULL, an empty label, spaces and the literal `None` as unlabelled. Other labels are trimmed and converted to upper case. `CUSTOMER_RECALL` stays visible as a supplied label. Its competition scope still needs confirmation from the organiser FAQ.

## 2. Evidence status

On 18 November 2026, the revised Python script processed the original 10,000,000-row CSV and wrote the four evidence files in [evidence/party/](../evidence/party/). The rerun reproduces the previously reported 7,006 labelled rows, the label profile and the customer-pair summaries shown below. It also found zero negative and zero zero-value payment rows.

The independent MySQL query exports and Python-versus-SQL comparison remain pending because the local MySQL server was not reachable during this run. Do not call the result a verified SQL cross-check until the comparison option reports a match. The Python script compares the three exported summary tables by their keys and numeric values and stops on a difference.

## 3. Reported label profile

| Label | Payments | Share of all payments | Payment value in USD | Share of labelled payment value |
|---|---:|---:|---:|---:|
| Romance scam | 2,476 | 0.02476% | $4.85m | 0.003% |
| Fat-finger mistake | 1,940 | 0.01940% | $175.14bn | 99.17% |
| CEO scam | 945 | 0.00945% | $1.31bn | 0.74% |
| Duplicate payment | 679 | 0.00679% | $96.65m | 0.05% |
| Account-replacement scam | 649 | 0.00649% | $37.20m | 0.02% |
| Customer recall | 317 | 0.00317% | $31.20m | 0.02% |
| All labelled payments | 7,006 | 0.07006% | $176.62bn | 100% |

The counts add to 7,006. Monetary figures are rounded, so displayed subtotals may differ from displayed totals. Use exact CSV sums for calculations.

Romance-scam labels are the most common of the listed labels. Fat-finger labels account for about 99.2% of the reported labelled payment value, although they represent about 27.7% of labelled payments. This is the value of payments carrying the labels. We do not know how much money was lost, recovered or settled.

Query 1 exports two different value shares:

- `share_of_all_payment_value_pct`: label value divided by the value of every payment, including unlabelled payments.
- `share_of_labelled_payment_value_pct`: label value divided by the value of all labelled payments. This is the denominator used in the table above. The unlabelled row has no share in this column.

Evidence file to upload: [evidence/party/label_profile.csv](../evidence/party/label_profile.csv).

## 4. Reported customer-group results

| Customer pair | All payments in pair | Labelled payments | Labelled rate | Labelled payment value |
|---|---:|---:|---:|---:|
| B to B | 2,270,945 | 1,060 | 0.0467% | $130.96bn |
| B to C | 5,603,692 | 2,727 | 0.0487% | $37.86bn |
| C to B | 610,605 | 843 | 0.1381% | $2.79bn |
| C to C | 1,514,758 | 2,376 | 0.1569% | $5.00bn |

The pair counts add to 10,000,000 and their labelled counts add to 7,006. Each rate uses all payments in that pair as its denominator.

The reported label rates are higher for payments from consumers. B-to-B has the largest labelled payment value. The overall label profile alone does not prove which label explains B-to-B value. Use query 3 to check the label mix within each pair before making that claim.

Evidence files to upload: query 2 gives `party_pair_profile.csv`; query 3 gives `party_pair_labels.csv`. Query 3 includes unlabelled rows so that counts reconcile. Each label rate still uses all payments in the pair.

## 5. Reported account examples

The earlier log reported a leading account with 35 labelled payments out of 41 beneficiary-side payments. It also reported an ordering account with 12 fat-finger labels out of 75,803 payments. The account IDs and result rows were not supplied, so these examples remain unconfirmed.

Run Python with `--accounts` to produce `account_label_history.csv`. This takes a second pass through the CSV. It saves every nonblank account-and-label combination found in labelled rows, including the total history count for that account role. A row's rate refers to its particular label, not necessarily every label on the account. Ordering and beneficiary roles remain separate. This cannot establish whether accounts in different roles belong to the same person.

Optional SQL query 4 checks one chosen account. Query 5 lists up to 200 payments for a chosen account pair. A repeated account pair, amount and currency can be legitimate. Check timestamps and supplied labels before proposing a duplicate rule. These optional queries still scan the table; no runtime is guaranteed.

## 6. Proposed rules to test

**Customer-pair hypothesis:** the generator may assign different label probabilities to different customer pairs. The overall reported rates support investigating this. Check each label separately using query 3. Geography and the mix of labels may explain part of the overall difference.

**Amount hypothesis:** the generator may make some fat-finger payments unusually large. Their reported value share supports investigating the idea. Compare amounts within the same customer pair before claiming a multiplier or threshold. Query 3 gives totals, but a specific amount rule needs distributions or thresholds from the payment-amount analysis.

**Account hypothesis:** the generator may reuse some beneficiary accounts across romance-labelled payments. Confirm the account evidence and compare with total activity before describing this as a rule.

These are hypotheses about generated data. A screening policy is a separate recommendation and does not explain how the dataset was created.

## 7. What Vincent should do next

1. Open the updated SQL in Workbench. Highlight and run query 1 only. Export the Result Grid as `evidence/party-sql/label_profile.csv`.
2. Run query 2 and export `evidence/party-sql/party_pair_profile.csv`. Run query 3 and export `evidence/party-sql/party_pair_labels.csv`. Keep numeric cells unformatted. Do not run the whole SQL file at once.
3. Run Python from the repository root. Change the path inside the quotes to the original CSV on your laptop:

   ```powershell
   python scripts/analyze_party_anomalies.py --source "C:/path/to/swift_payments.csv" --output-dir evidence/party --compare-dir evidence/party-sql
   ```

   This reads the CSV once and checks all three SQL exports. It uses Python's standard library. If the comparison fails, keep both sets of results and investigate the named row and column. Do not edit numbers just to make them match. Python stops on missing or invalid amounts rather than silently skipping records.

4. Check `quality_counts.csv` for 10,000,000 rows, 7,006 reported labelled rows, and any unexpected customer codes. Zero and negative amounts are counted and retained, as in the SQL. Confirm any difference from the earlier log.
5. Only if account examples are needed, rerun with `--accounts` added. This reads the CSV twice. Pick a nonblank account from the output, enter its role and ID in SQL query 4, and compare the account counts.
6. Upload the generated evidence CSVs to `party-anomalies`. Keep the 5 GB original CSV out of GitHub. Update this log with the actual rerun totals and the comparison status.
7. Make a chart of labelled rates by customer pair and a chart of labelled payment value by label. State the denominator on each chart. Use the label-by-pair table to decide which proposed rule the evidence supports. Discuss sensible feature grouping with the team so each feature group has at most one findings slide.

The fastest useful next step is queries 1-3 and their saved results. Account and duplicate checks are optional follow-up work.

## 8. Limits and unresolved checks

- The labels come from fictitious data. They do not establish real fraud rates or customer behaviour. Customer recall may describe a different kind of event from a scam.
- Bank location does not establish customer nationality. Label rates can differ because countries, banks or customer groups have different mixes of payments.
- Payment value does not measure loss. The summaries do not establish settlement outcomes or payment purpose.
- The extra country checks in the currency work do not validate these anomaly rules. These hypotheses need their own supporting checks.
- The earlier log reported 972,971 BIC-path endpoint mismatches, 767,204 path/participant-count mismatches, and an exact match between the continuity flag and a path consistency check. No supporting routing query or result was included in these three files. These remain unverified routing claims. Get the routing evidence from that workstream before using them.
- Python uses Decimal for sums. The scripts normalise label case and ASCII spaces. MySQL collation can still handle unusual characters or account IDs differently from Python. The comparison step helps reveal differences in summaries; selected account checks need their own review.
- Python's optional account pass stores labelled account keys in memory. It avoids storing all ten million rows, but memory use still grows with the number of labelled accounts.
