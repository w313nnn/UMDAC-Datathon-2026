# UMDAC Datathon 2026 team guide

## What we are doing

Swift supplied 10 million synthetic payment records. Each row represents a payment instruction. Our task is to reconstruct the rules and relationships that generated these records, support each proposed rule with evidence, and explain the economic behaviour it might represent.

Our workflow is raw CSV -> MySQL analysis -> small summary tables -> Excel dashboard -> PDF submission. The raw CSV is about 4.95 GB. A normal Excel worksheet holds at most 1,048,576 rows, so use MySQL for full-data calculations.

## Understanding the columns

| Columns | Meaning |
|---|---|
| EPOCH_SECONDS | Payment time in Unix seconds, convertible to UTC |
| CURRENCY_CODE | Currency used for the payment |
| USD_AMOUNT | Payment value expressed in USD, even when another currency was used |
| ORDERING_BIC8 / BENEFICIARY_BIC8 | Sending / receiving bank identifiers. Characters 5-6 encode the bank country |
| ORDERING_TYPE / BENEFICIARY_TYPE | Sender / receiver type. B means business, C means consumer |
| ORDERING_ACCOUNT / BENEFICIARY_ACCOUNT | Synthetic account IDs for analysing repeated activity |
| BIC8_PATH | Sequence of banks in the payment route |
| TOTAL_DURATION | Route duration in seconds |
| PARTICIPANT_COUNT | Number of institutions involved |
| CURRENCY_CONVERSION_COUNT | Number of FX conversion steps |
| TRANSACTION_TYPE_CODE | Direct, Indirect or Covered routing category |
| CONTINUITY_QFLAG | Whether the complete route is observable |
| ORDERING_DETAILS / BENEFICIARY_DETAILS | Synthetic party-detail text |
| ORDERING_TOKENS / BENEFICIARY_TOKENS | Engineered summaries of patterns in that text |
| ANOMALY_TYPE | Optional supplied anomaly label |
| DISCLAIMER | Dataset notice |

Bank country describes the institution. Customer location may differ. Blank anomaly labels remain unlabeled unless their meaning is established.

## Suggested division of work

| Member | Analysis | Coordination |
|---|---|---|
| Wei En | Currency use and payment values | MySQL setup, data checks and slide assembly |
| Hui Min | Routing, duration and currency conversions | Excel layout and dashboard PDF assembly |
| Vincent | Party behaviour and labeled anomalies | Cross-checking results and troubleshooting |

Each member saves the SQL, result tables, charts and explanation for their own findings. Review one another's calculations.

## Current import status

Database swift_datathon, table swift_payments, MySQL 8.0.44.
The user reported 10,000,000 rows imported, zero skipped and zero warnings. This establishes successful loading. Further analytical data checks remain part of the methodology.

## What we have learned

### First question — do businesses use USD more frequently?

| Sender | Payments | USD payments | USD share |
|---|---:|---:|---:|
| Business | 7874637 | 1362252 | 17.30% |
| Consumer | 2125363 | 340739 | 16.03% |

The overall gap is approximately 1.27 percentage points.

### Checking country composition

The groups have different sending-bank country mixes. Giving them the same weights means calculating each group's USD share as if both had the same distribution of sending-bank countries. We used each country's combined business and consumer payment count to set its weight.

The calculation covered 226 countries and 9,999,993 payments. Both sender types had to be present in a country. Seven records were outside the eligible comparison; their exact exclusion reason has not yet been investigated.

| Measure | Result |
|---|---:|
| Adjusted business USD share | 17.0297% |
| Adjusted consumer USD share | 17.0332% |
| Adjusted gap | -0.0036 percentage points |

The gap is approximately zero after this adjustment. Country composition accounts for most of the aggregate association in the covered data. This does not establish independence within every country or identify a causal mechanism.

### Testing US bank involvement

| Bank group | Payments | USD payments | USD share |
|---|---:|---:|---:|
| Neither bank in US | 6879148 | 159855 | 2.32% |
| Receiving bank in US only | 1538437 | 110678 | 7.19% |
| Sending bank in US only | 1196817 | 1070259 | 89.43% |
| Both banks in US | 385598 | 362199 | 93.93% |

These counts cover all 10 million imported payments and reconcile to 1,702,991 USD payments.

Candidate rule — in this synthetic dataset, USD use is strongly associated with a US sending bank. USD is used for about 89-94% of payments with a US sending bank. With a non-US sending bank, a US receiving bank is associated with a smaller increase in USD use.

These percentages describe observed conditional frequencies. The original generating code remains unknown. Comparisons within sending countries, bank corridors and time periods can test how broadly this candidate rule holds.

Possible economic interpretation — currency choice may reflect the sending institution's operating environment and the destination. This is a hypothesis to support with further checks. The dataset's artificial population sizes and country proportions need not match real-world markets.

## Build the first Excel dashboard

1. Open Excel and create a blank workbook. Save it as UMDAC_Currency_Use.xlsx.
2. Rename the first worksheet Currency_Data.
3. Copy the tab-separated block below and paste it into A1. If everything appears in one column, use Data > Text to Columns > Delimited > Tab.
4. In D1 enter USD share. In D2 enter =C2/B2, then fill down through D5. Format D2:D5 as Percentage with two decimal places. The underlying values are fractions such as 0.0232.
5. In A7 enter Total. In B7 enter =SUM(B2:B5), and in C7 enter =SUM(C2:C5). Check for 10000000 and 1702991.
6. Select A1:A5, hold Ctrl, and select D1:D5. Choose Insert > Bar Chart > 2-D Clustered Bar. The chart should have four bars and one data series.
7. Right-click the horizontal value axis and choose Format Axis. Set Minimum to 0, Maximum to 1 and Major unit to 0.2. Format axis numbers as Percentage.
8. Add data labels and format them as percentages with two decimal places. Remove the legend if it only repeats USD share. Use a consistent colour and readable labels.
9. Create a second worksheet called Currency_Dashboard. Cut the chart and paste it onto this sheet.
10. Put Currency use at the top. Use the chart title USD use is highest when the sending bank is in the US.
11. Add the candidate rule from the results section as a wrapped text box beneath the chart. Add a small table of payment counts for the four groups.
12. Add a methodology note — Grouped all 10 million payments by US sending/receiving bank status. USD share equals USD payments divided by all payments in each group. Bank countries come from characters 5-6 of the BIC8 identifiers. Labeled anomalies are included.
13. Add a short supporting note — The business-consumer USD gap changed from about 1.27 percentage points to -0.0036 points after matching sending-bank country weights across 9,999,993 payments.
14. Add a limitation — Synthetic dataset. Conditional associations are observed; the exact generating rules and causal mechanism remain under investigation.
15. Hide worksheet gridlines using View > Gridlines. Arrange the title, chart and notes so everything reads comfortably on one page.
16. Select the dashboard area and choose Page Layout > Print Area > Set Print Area. Set Landscape, A4, and scaling to one page wide by one page tall.
17. Check File > Print. Resize the chart or shorten text if it becomes too small. Ensure all four labels, percentages and notes are legible.
18. Export the active dashboard sheet as PDF. Check the PDF has exactly one readable page. Save the editable workbook too.

Bank group	Payment count	USD count
Neither bank in US	6879148	159855
Receiving bank in US only	1538437	110678
Sending bank in US only	1196817	1070259
Both banks in US	385598	362199

This is one Currency use dashboard page within the team's 5-15 dashboard pages. It can develop as more evidence arrives.

## SQL behind the four-row chart

```sql
WITH bank_locations AS (
    SELECT
        SUBSTRING(ordering_bic8, 5, 2) = 'US' AS sending_bank_us,
        SUBSTRING(beneficiary_bic8, 5, 2) = 'US' AS receiving_bank_us,
        currency_code = 'USD' AS uses_usd
    FROM swift_datathon.swift_payments
    WHERE CHAR_LENGTH(ordering_bic8) = 8
      AND CHAR_LENGTH(beneficiary_bic8) = 8
      AND NULLIF(TRIM(currency_code), '') IS NOT NULL
)
SELECT
    CASE
        WHEN sending_bank_us AND receiving_bank_us THEN 'Both banks in US'
        WHEN sending_bank_us THEN 'Sending bank in US only'
        WHEN receiving_bank_us THEN 'Receiving bank in US only'
        ELSE 'Neither bank in US'
    END AS bank_group,
    COUNT(*) AS payment_count,
    SUM(uses_usd) AS usd_count,
    ROUND(100.0 * SUM(uses_usd) / COUNT(*), 2) AS usd_share_pct
FROM bank_locations
GROUP BY sending_bank_us, receiving_bank_us
ORDER BY sending_bank_us, receiving_bank_us;
```

## Deliverables and judging

The organiser’s final announcement sets the preliminary deadline at 11:59 PM on 19 November 2026. Upload both PDFs before the deadline. The organiser disallows edits, additions and replacements after submission. Use the official submission form linked in the team Discord.

- Dashboard PDF with 5-15 pages, organised by feature group, showing proposed rules and supporting charts.
- Presentation PDF with 10-20 slides including introduction and methodology. At most one findings slide per feature group.
- The detailed rubric allocates 45% to insight quality, 23% to evidence/method/data integrity, 20% to communication and 12% to interpretation/economic reasoning.
- The Submission Format document also gives separate dashboard and slide breakdowns. Their relationship to the detailed rubric needs organizer clarification.
- AI assistance is allowed. Every team member should understand and explain their work.
- Use the supplied dataset for primary analysis. Cite permitted external reference statistics in APA format.
- Keep substantive competition work within the registered team. The competition prohibits unauthorized dataset redistribution.

## Next analysis

For Currency use, check whether the receiving-US association persists within individual non-US sending-bank countries. Test stability over time and document exceptions.

For Payment values, compare business-to-business, business-to-consumer, consumer-to-business and consumer-to-consumer payments within the same currency. Study medians or amount bands alongside averages, and assess the influence of labeled anomalies.

For each result, save the hypothesis, query, filters, counts, calculation, chart, interpretation, alternative explanations tested and remaining uncertainty.
