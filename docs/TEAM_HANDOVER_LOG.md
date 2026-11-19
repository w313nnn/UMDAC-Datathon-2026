# Team handover: findings and SQL files

Updated: 16 November 2026  
For Hui Min, Vincent and our team. The scripts are in the [sql folder](../sql/).

## How to use this log

This is the short guide for building our dashboard and slides. The [full insights log](INSIGHTS_LOG.md) contains more evidence. Read the [SQL guide](SQL_GUIDE.md) before running scripts.

Each section below tells you:
- **Finding:** what the numbers show.
- **Insight:** what the pattern may mean.
- **SQL:** where to get the evidence.
- **Chart:** a useful way to show it.
- **Limit:** what we should not claim.

These are synthetic payments, not real-world country risk statistics. B means business and C means consumer. Country codes describe banks, not customer nationality. Counts describe payments, not unique clients.

## 1. Country mix explains the overall business–consumer USD gap

**Finding**
- Businesses used USD in 17.30% of payments; consumers in 16.03%.
- After giving both groups the same sending-country mix: 17.0297% versus 17.0332%.
- Adjusted gap: -0.0036 percentage points.
- Adjustment covered 9,999,993 payments across 226 country codes.

**Insight:** the overall difference almost disappears when we account for sending-bank country. We should not present it as a simple business-versus-consumer preference.

**SQL:** [currency_use.sql](../sql/currency_use.sql), queries 1 and 2.

**Chart:** grouped bars showing business and consumer USD shares before and after adjustment.

**Limit:** seven payments were outside the adjusted comparison. This does not prove customer type never matters.

## 2. Currency use is linked with both bank locations

**Finding**

| Bank group | Payments | USD share |
|---|---:|---:|
| Neither bank in US | 6,879,148 | 2.32% |
| Receiving bank only in US | 1,538,437 | 7.19% |
| Sending bank only in US | 1,196,817 | 89.43% |
| Both banks in US | 385,598 | 93.93% |

Other origins also favoured particular currencies: GB→GBP 88.55%, SG→SGD 87.55%, MY→MYR 89.78%, FR→EUR 94.02%.

Within fixed origins:
- GB→GB EUR use was 3.55%; GB→FR 11.32%; GB→DE 11.53%.
- SG→SG EUR use was 4.02%; SG→FR 12.67%; SG→DE 12.47%.
- SG→CN CNY use was 6.34% (855/13,478), versus 0.24% (51/21,329) for SG→SG.
- That CNY difference persisted within business senders (6.25% versus 0.21%) and consumer senders (6.59% versus 0.36%).

**Insight / candidate rule:** the sending location's currency is often dominant, while receiving location helps explain additional currency differences.

**SQL**
- [currency_use.sql](../sql/currency_use.sql), query 3: four US-location groups.
- [currency_country_patterns.sql](../sql/currency_country_patterns.sql): main currencies by origin.
- [currency_receiving_country.sql](../sql/currency_receiving_country.sql): GB origin.
- [currency_receiving_country_sg.sql](../sql/currency_receiving_country_sg.sql): SG origin.
- [currency_sg_cn_breakdown.sql](../sql/currency_sg_cn_breakdown.sql): individual currencies for SG→CN and SG→SG.
- [currency_sg_cn_sender_type.sql](../sql/currency_sg_cn_sender_type.sql): separate business and consumer senders.

**Chart:** horizontal bars for the four US-location groups; a small comparison chart for CNY or EUR as supporting evidence.

**Possible explanation:** currency choice may reflect needs on both sides of a payment. This is an interpretation, not a proven customer motive.

**Limits:** most-used does not mean favourite. The summaries do not show who selected the currency or the recipient's final settlement currency. The country-pattern query displays only origins with at least 10,000 eligible payments.

## 3. Customer-type pairs have different typical payment amounts

**Finding — USD amounts**

| Group | Payments | Median | P90 | Average |
|---|---:|---:|---:|---:|
| B→B | 2,270,945 | $22,887.71 | $400,927.27 | $310,506.47 |
| B→C | 5,603,692 | $3,119.00 | $54,660.83 | $40,992.03 |
| C→B | 610,605 | $3,229.06 | $56,439.37 | $40,290.27 |
| C→C | 1,514,758 | $463.17 | $7,821.83 | $8,311.40 |

Median means the middle amount. P90 is an amount at or below which at least 90% of payments fall.

The same broad ordering held at median and P90:
- Within CN, GB, MY, SG and US sending-bank countries.
- Within GB→GB, GB→US, SG→CN, SG→SG, SG→US and US→US pairs.

For example, within SG→CN, B→B median was $40,355.07 versus $696.29 for C→C.

**Insight / candidate rule:** two-business payments tend to be largest, mixed pairs intermediate and two-consumer payments smallest. The pattern remains in the country groups and pairs tested.

**SQL**
- [payment_amount_profile.sql](../sql/payment_amount_profile.sql): counts, averages and basic checks.
- [payment_amount_percentiles.sql](../sql/payment_amount_percentiles.sql): overall medians and P90.
- [payment_amount_by_sending_country.sql](../sql/payment_amount_by_sending_country.sql): five origins.
- [payment_amount_by_country_pair.sql](../sql/payment_amount_by_country_pair.sql): six pairs.

**Chart:** colour-shaded table of medians by country pair and customer group. Show P90 separately if needed; avoid squeezing very different values onto an unreadable scale.

**Possible explanation:** business-related obligations may be larger. We cannot identify salaries, purchases or invoices from these summaries.

**Limits:** amounts expressed in USD do not mean USD was the payment currency. Mixed-group directions are not always equal. Geography, bank, currency, time and account composition may still matter.

## 4. Large values make averages much higher than typical amounts

**Finding:** every customer group's average is much higher than its median. C→C average is $8,311.40 versus median $463.17. The largest B→B payment is about $15.66 billion.

Within C→C:
- SG→US average $5,833.54; median $675.90.
- US→US average $24,819.80; median $760.91.

**Insight:** averages can give a very different impression from typical payments because of the large upper end. Use median with P90 when explaining payment size.

**SQL:** [payment_amount_profile.sql](../sql/payment_amount_profile.sql), [payment_amount_percentiles.sql](../sql/payment_amount_percentiles.sql), [payment_amount_by_country_pair.sql](../sql/payment_amount_by_country_pair.sql).

**Chart:** average-versus-median comparison, or use this as a note on the amount page.

**Limit:** large does not automatically mean erroneous. We have not established a particular mathematical distribution.

## 5. Large amounts are linked with some anomaly labels, but miss most labels

**Finding**
- Total labels: 7,006 out of 10 million payments (0.07006%).
- Romance 2,476; fat-finger 1,940; CEO 945; duplicate 679; account replacement 649; recall 317.
- We used each customer group's P99 as its large-payment threshold.
- Fat-finger label rates were about 62–84 times higher in the upper band than below it.
- 850 of 1,940 fat-finger labels (43.8%) were in the upper bands.
- CEO label rates were about 12 times higher for B→B and 24 times higher for B→C.
- Upper bands contained 100,002 payments and 1,036 labels: only 1.04% of flagged payments carried a label.
- Those bands captured only 14.79% of all labels.
- Only 3 of 2,476 romance labels were in the upper bands.

**Insight:** different label types have different amount patterns. A single large-payment rule is not enough.

**SQL:** [payment_amount_anomaly_check.sql](../sql/payment_amount_anomaly_check.sql). Query 1 lists labels; query 2 compares bands.

**Chart:** label rates above/below P99 by customer group, or a short comparison of labels captured versus missed.

**Possible explanation:** some amount-entry mistakes may create unusually large values. The exact mistake or multiplier is not established.

**Limits:** NULL means unlabelled, not verified legitimate. This is exploratory analysis, not a detector tested on unseen data. Check official definitions before interpreting labels.

**Runtime:** the second query previously took about 59 minutes. Use saved results rather than rerunning it just to draw a chart.

## 6. The romance small-payment pattern changes after country comparisons

**Finding**
- Overall, 48.7% of romance labels were below $100, while only about 20.1% of consumer payments were below $100.
- But the relationship sometimes reversed within sending countries.

For consumer recipients with banks in different countries:

| Sending code | Labels per 10,000 below $100 | Labels per 10,000 at $100+ |
|---|---:|---:|
| IN | 667.67 | 513.30 |
| CN | 22.40 | 154.36 |
| BR | 88.26 | 392.89 |
| US | 0.00 | 7.18 |

**Insight:** “small payments have more romance labels” is a pooled observation, not a universal rule. Country and recipient composition matter.

**SQL**
- [romance_scam_profile.sql](../sql/romance_scam_profile.sql): pooled amount bands and bank-country relationship.
- [romance_small_payments_by_country.sql](../sql/romance_small_payments_by_country.sql): country comparisons.

**Chart:** small-versus-larger rate bars for selected countries, including both supporting examples and reversals.

**Limits:** the country query only displays groups with at least 1,000 payments in both bands. The $100+ band is not the same as the P99 band. Zero observed labels does not prove impossibility.

## 7. Romance labels are concentrated in particular country pairs

**Finding**
- India-origin: 467 labels among 8,221 consumer payments.
- China-origin: 435 among 47,741.
- Together: 36.43% of romance labels but 2.63% of consumer payments.
- US-origin: 130 labels, but only 4.23 per 10,000 payments because its payment volume is much larger.

Selected pairs, both recipient types combined:

| Pair | Payments | Labels | Label percentage |
|---|---:|---:|---:|
| IN→CN | 428 | 66 | 15.42% |
| IN→EG | 56 | 52 | 92.86% |
| CN→EG | 69 | 49 | 71.01% |
| CN→CN | 2,473 | 38 | 1.54% |
| CN→IQ | 70 | 38 | 54.29% |
| CN→GB | 3,926 | 14 | 0.36% |

IN→CN had the most labels in the ranking; it did not have the highest rate. ID→ID also had 16 labels among 16 payments, so different-country banks are not required.

**Insight / candidate rule:** receiving location adds important information. Labels are unevenly concentrated in particular bank-country pairs, rather than being explained by sending country or amount alone.

**SQL**
- [romance_labels_by_sending_country.sql](../sql/romance_labels_by_sending_country.sql): origins and recipient type.
- [romance_labels_by_country_pair.sql](../sql/romance_labels_by_country_pair.sql): full pairs and recipient type.
- [romance_top_country_pairs.sql](../sql/romance_top_country_pairs.sql): top 30 pairs, recipient types combined.

**Chart:** counts and rates side by side, with total payment counts visible. A 100% rate based on 16 records must not look as certain as a rate based on thousands.

**Limits:** synthetic data only. These are not real-world country risk ratings. Top pairs were selected from the same labelled dataset. Repeated accounts, bank identity and time have not yet been checked.

**Output note:** the full pair query returns 31,235 groups, including zero-label groups. Use the top-30 version for a readable summary.

## What to prepare for each dashboard finding

1. Export the relevant small result table from Workbench as CSV.
2. Keep the SQL filename beside the result so someone else can reproduce it.
3. Add one clear chart.
4. Write one sentence saying what the chart shows.
5. Write the candidate business rule separately.
6. Include the sample size, filters and a short limitation.
7. For slides, describe the method and label economic explanations as possible explanations.

Do not turn every query into a separate page. Queries often support the same finding. Follow the final submission limits and feature-group requirements when combining pages/slides.

Do not rerun the CSV import if the data is already loaded. All analysis scripts need MySQL 8.0 and the table swift_datathon.swift_payments. See [SQL_GUIDE.md](SQL_GUIDE.md).

## Team handover checklist

This is a suggested work split to agree together, not a new assignment imposed on anyone.

- **User:** provide currency/amount evidence, explanations and basic charts; check their correctness.
- **Hui Min:** continue routing/duration work and help combine charts into a consistent dashboard.
- **Vincent:** continue anomaly/party investigations, challenge claims and help verify final results.
- **Everyone:** read the findings, keep limitations, and check the final charts and slides.

The currency, amount and romance sections are ready for initial chart building. Other feature groups still need team coverage. Run new SQL when it answers a specific missing question, not simply to produce more tables.

## Data checks already completed

- 10 million rows imported, zero skipped rows and import warnings; later count matched.
- All amounts positive and non-missing in the amount check.
- Four expected B/C combinations observed.
- Consumer-origin totals reconcile to 2,125,363 payments and 2,476 romance labels.

These checks are useful but are not a complete audit of every data field.

## Additional-country checks and what they add

Updated: 18 November 2026. Supporting SQL: [validate_currency_and_amount_rules.sql](../sql/validate_currency_and_amount_rules.sql). Results supplied by the team are recorded on the workbook's Additional_Country_Checks tab.

| Sending bank country | Local share, non-US receiver | Local share, US receiver | USD share, non-US receiver | USD share, US receiver |
|---|---:|---:|---:|---:|
| AU | 83.99% | 83.07% | 2.19% | 8.29% |
| CA | 85.08% | 79.49% | 3.08% | 12.73% |
| JP | 88.62% | 86.45% | 1.68% | 6.33% |

Local currency remains common in all six groups. USD share rises with a US receiving bank in all three origins. This supports a rule where sending location sets much of the currency mix and receiving location adjusts it. It does not show who chose the currency.

For AU to US, CA to US and JP to US, B-to-B has the highest share above each amount threshold ($1,000, $10,000 and $100,000), and C-to-C has the lowest. Mixed groups fall between them, with no fixed order. The smallest customer group has 1,547 payments.

At $10,000, the shares are:

| Pair | B to B | B to C | C to B | C to C |
|---|---:|---:|---:|---:|
| AU to US | 68.94% | 31.08% | 30.82% | 7.07% |
| CA to US | 70.54% | 33.30% | 35.16% | 7.75% |
| JP to US | 57.42% | 23.49% | 22.42% | 3.75% |

These checks use additional countries, but the records were already in the overall summaries. They are not independent holdouts. All amount-validation routes end in the US. Thresholds support the broad amount ordering but do not recover the exact generation formula.

### What Swift can learn from these findings

Currency: an overall customer-type comparison can be misleading when the bank-country mixes differ. Compare similar geographic groups before interpreting a difference as customer behaviour. The adjusted business/consumer USD gap almost disappears.

Amounts: a single typical payment value hides large differences between customer pairs. Medians describe the middle more clearly than averages when the upper end is large. Geography still matters within customer groups.

These are explanations of the synthetic dataset. Payment motives and operational outcomes are unknown. We have not measured financial savings, fraud losses or a production detection benefit.

### Before combining the final submission

Each feature group should state its proposed generation rule, show the relevant denominator and chart, explain the method, and keep the main limitation visible. Label economic explanations as possible explanations. Currency and amounts cover two parts of the dataset; routing, duration, conversion and anomaly results still need team review. Avoid presenting a collection of charts as a complete reconstruction of all 21 fields.
