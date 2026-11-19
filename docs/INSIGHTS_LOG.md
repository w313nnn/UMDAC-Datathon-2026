# Our datathon findings: a simple team guide

Updated: 16 November 2026  
For: our UMDAC Datathon 2026 team

## Read this first

We are studying **made-up payment data**. Our job is to find patterns that may explain how the data was created.

These findings come from SQL results shared during our analysis. They are not claims about real countries, real customers or real crime rates.

**A pattern is not proof of a cause.** For example, if a currency is common for a bank location, we know it was used often. We do not know who chose it or why.

The SQL links below open the team’s scripts in the [sql folder](../sql/).

## Words we use

| Word | Simple meaning |
|---|---|
| B / C | Business / Consumer |
| Sending / receiving bank | The bank on each side of a payment |
| Bank country | Country code taken from the bank's BIC; not the customer's nationality |
| Median | Middle payment amount after sorting amounts; useful for describing a typical payment |
| P90 | An amount at or below which at least 90% of payments fall |
| P99 | An amount at or below which at least 99% of payments fall |
| Percentage points | Difference between percentages: 6% minus 2% is 4 percentage points |
| Label rate | Labelled payments divided by all payments in that group |
| NULL label | No label recorded; not proof that a payment is legitimate |
| Country pair | Sending-bank country and receiving-bank country, such as SG → CN |
| Candidate rule | A possible rule supported by results, but not an exact rule we have proved |

Amounts in the amount analysis are expressed in USD. This does not mean all those payments used USD as their payment currency. Our counts describe payments, not unique people.

## 1. Basic data checks

**D01 — Import succeeded.** We imported 10,000,000 payments, with zero skipped rows and zero import warnings. A later row count matched.

- SQL: [import_swift.sql](../sql/import_swift.sql)
- Limit: this confirms the import, not that every value is realistic.

**D02 — Basic amount checks passed.** All 10 million payments had a positive, non-missing amount. The four B/C sender–recipient combinations appeared. Each group's minimum was $0.01.

- SQL: [payment_amount_profile.sql](../sql/payment_amount_profile.sql)
- Limit: we have not completed every data-quality check. Positive amounts can still be mistakes.

## 2. Currency: what money unit was used?

### C01 — The overall business–consumer difference mostly came from country mix

Businesses used USD in 17.30% of payments; consumers used it in 16.03%.

We then gave both groups the same sending-country weights, so their country mixes were comparable:

| Group | Adjusted USD share |
|---|---:|
| Business | 17.0297% |
| Consumer | 17.0332% |

The adjusted difference was only -0.0036 percentage points.

**Meaning:** the original gap almost disappeared after accounting for sending-bank country.

- SQL: [currency_use.sql](../sql/currency_use.sql)
- Coverage: 226 country codes and 9,999,993 payments; seven payments were outside this comparison.
- Limit: this does not mean customer type never matters.

### C02 — US sending banks were strongly linked with USD use

| Bank locations | Payments | USD share |
|---|---:|---:|
| Neither bank in US | 6,879,148 | 2.32% |
| Receiving bank only in US | 1,538,437 | 7.19% |
| Sending bank only in US | 1,196,817 | 89.43% |
| Both banks in US | 385,598 | 93.93% |

- SQL: [currency_use.sql](../sql/currency_use.sql)
- Limit: this is about bank locations, not customer nationality or personal preference.

### C03 — Other sending locations also favoured particular currencies

| Sending-bank code | Most-used currency | Share |
|---|---|---:|
| US | USD | 90.52% |
| CH | CHF | 88.77% |
| GB | GBP | 88.55% |
| SG | SGD | 87.55% |
| CN | CNY | 86.18% |
| MY | MYR | 89.78% |
| FR | EUR | 94.02% |
| DE | EUR | 94.46% |

- SQL: [currency_country_patterns.sql](../sql/currency_country_patterns.sql)
- Coverage: 86 country/territory codes with at least 10,000 eligible payments.
- Limit: shares differ; do not claim every country uses one currency exactly 90% of the time. A full country–currency mapping has not been checked.

### C04 — Receiving location also matters within a fixed origin

| Pair | EUR share | USD share |
|---|---:|---:|
| GB → GB | 3.55% | 1.39% |
| GB → FR | 11.32% | 1.50% |
| GB → DE | 11.53% | 1.75% |
| GB → US | 3.76% | 5.72% |
| SG → SG | 4.02% | 1.53% |
| SG → FR | 12.67% | 1.62% |
| SG → DE | 12.47% | 1.83% |
| SG → US | 3.94% | 5.49% |

**Meaning:** EUR use was higher for French and German destinations. USD use was higher for US destinations. The sending location's main currency still dominated these examples.

- SQL: [currency_receiving_country.sql](../sql/currency_receiving_country.sql), [currency_receiving_country_sg.sql](../sql/currency_receiving_country_sg.sql)
- Important correction: the Singapore currency code is **SGD**, not SG. Use the corrected saved query.
- Limit: these are selected examples, and other factors may differ between groups.

### C05 — The CNY example supports the same idea

- SG → CN: 855 of 13,478 payments used CNY: **6.34%**.
- SG → SG: 51 of 21,329 used CNY: **0.24%**.
- CNY accounted for 855 of the 1,215 payments previously grouped as “other currencies” for SG → CN: **70.37%**.
- Among business senders, CNY shares were **6.25% versus 0.21%**.
- Among consumer senders, they were **6.59% versus 0.36%**.

**Meaning:** the destination pattern remained after separating business and consumer senders.

- SQL: [currency_sg_cn_breakdown.sql](../sql/currency_sg_cn_breakdown.sql), [currency_sg_cn_sender_type.sql](../sql/currency_sg_cn_sender_type.sql)
- Limit: we cannot infer the recipient's final currency, conversion details or customer motives from these summaries.

**Working currency rule:** currency use is linked with both bank locations. Sending location has a strong association, while receiving location helps explain additional differences.

**Chart idea:** USD shares for the four US-location groups, plus a small fixed-origin destination comparison.

## 3. Amounts: how big were the payments?

### P01 and P02 — Customer groups differ, and large values pull up averages

All values below are expressed in USD.

| Group | Payment count | Median | P90 | Average |
|---|---:|---:|---:|---:|
| B → B | 2,270,945 | $22,887.71 | $400,927.27 | $310,506.47 |
| B → C | 5,603,692 | $3,119.00 | $54,660.83 | $40,992.03 |
| C → B | 610,605 | $3,229.06 | $56,439.37 | $40,290.27 |
| C → C | 1,514,758 | $463.17 | $7,821.83 | $8,311.40 |

**Meaning:** two-business payments tend to be largest; mixed pairs sit in the middle; two-consumer payments tend to be smallest.

Every average is much higher than its median. Large payments strongly affect the averages. The largest B → B payment was about $15.66 billion.

- SQL: [payment_amount_profile.sql](../sql/payment_amount_profile.sql), [payment_amount_percentiles.sql](../sql/payment_amount_percentiles.sql)
- Limit: an extreme amount is not automatically an error. Similar mixed-group summaries do not mean identical distributions. We have not identified a mathematical distribution.

### P03 — The ordering remained within sending countries

In CN, GB, MY, SG and US, the same broad ordering appeared at both the median and P90.

Geography also differed: B → B medians were $6,915.54 for CN, $7,038.39 for MY, $24,037.41 for GB, $41,811.10 for SG and $46,170.87 for US.

- SQL: [payment_amount_by_sending_country.sql](../sql/payment_amount_by_sending_country.sql)
- Limit: five selected origins; differences in destinations, banks and currencies remain.

### P04 — The ordering remained within fixed country pairs

Median amounts, rounded to the nearest dollar:

| Bank-country pair | B → B | B → C | C → B | C → C |
|---|---:|---:|---:|---:|
| GB → GB | $25,885 | $3,690 | $3,724 | $513 |
| GB → US | $25,212 | $3,316 | $3,367 | $480 |
| SG → CN | $40,355 | $5,358 | $4,556 | $696 |
| SG → SG | $47,285 | $6,418 | $5,578 | $731 |
| SG → US | $40,530 | $5,301 | $4,758 | $676 |
| US → US | $46,199 | $6,000 | $5,700 | $761 |

The same ordering held at P90. Every group contained at least 1,151 payments. B → B medians were about 50–65 times C → C medians within these pairs.

- SQL: [payment_amount_by_country_pair.sql](../sql/payment_amount_by_country_pair.sql)
- Limit: selected pairs, not every pair. Individual banks, accounts, time and currency remain uncontrolled. Mixed-group direction sometimes differs, so do not call those groups identical.

**Working amount rule:** customer-type combinations are associated with payment size, even when we compare the same bank-country pair.

**Chart idea:** a colour-shaded table of within-pair medians, with P90 as supporting evidence.

## 4. Anomaly labels: does unusually large mean unusual behaviour?

### A01 — Labels are rare

| Label | Count |
|---|---:|
| ROMANCE_SCAM | 2,476 |
| FAT_FINGER_MISTAKE | 1,940 |
| CEO_SCAM | 945 |
| DUPLICATE_PAYMENT | 679 |
| ACCOUNT_REPLACEMENT_SCAM | 649 |
| CUSTOMER_RECALL | 317 |
| No label (NULL) | 9,992,994 |

There are **7,006 labelled payments**, or **0.07006%** of all payments.

### A02 — Fat-finger and CEO labels were more common in the large-amount band

We used separate P99 amount thresholds for each group:

| Group | P99 threshold |
|---|---:|
| B → B | $3,857,454.75 |
| B → C | $524,843.47 |
| C → B | $549,565.80 |
| C → C | $76,451.31 |

Fat-finger label rates were about **62–84 times higher** at or above P99 than below it. **850 of 1,940 fat-finger labels (43.8%)** were in those upper bands.

CEO label rates were about **12 times higher for B → B** and **24 times higher for B → C** in the upper band.

A possible explanation is that some typing mistakes create large amounts. We have not proved the exact mistake or multiplier.

### A03 — Amount alone misses most labels

- Payments at or above the group P99 thresholds: **100,002**.
- Labelled payments there: **1,036**, or **1.04%** of that band.
- Share of all labels captured: **14.79%**.
- Labels below the thresholds: **5,970**.
- Only **3 of 2,476 romance labels** were in the upper bands.

**Meaning:** flagging large payments alone would miss most labels and flag many unlabelled records.

- SQL for A01–A03: [payment_amount_anomaly_check.sql](../sql/payment_amount_anomaly_check.sql)
- Limits: NULL is not verified normal. Label definitions need checking against the case documentation. These thresholds were tested on the same data used to calculate them, not unseen data. Ties make the upper band slightly larger than 1%.
- Runtime note: this query took about **59 minutes**. Keep its results; do not rerun it without a reason.

## 5. Romance labels: what changed as we investigated?

### R01 — At first, smaller payments looked more strongly linked with the label

Across consumer-origin payments, **1,206 of 2,476 labels (48.7%)** were below $100. That band contained only about **20.1%** of consumer payments.

The highest initial subgroup rate was consumer → business, different bank countries, under $100: **309 labels among 40,791 payments (0.7575%)**.

- SQL: [romance_scam_profile.sql](../sql/romance_scam_profile.sql)
- Limit: this pooled result mixes countries. Do not turn it into a universal rule.

### R02 — Within countries, the small-payment pattern sometimes reversed

For consumer recipients and different bank countries:

| Sending code | Labels per 10,000 below $100 | Labels per 10,000 at $100+ |
|---|---:|---:|
| IN | 667.67 | 513.30 |
| CN | 22.40 | 154.36 |
| BR | 88.26 | 392.89 |
| US | 0.00 | 7.18 |

For CN with business recipients, the pattern went the other way: **117.46 below $100 versus 66.74 at $100+**.

**Meaning:** country and recipient type change the comparison. The overall small-payment association is not consistent everywhere.

- SQL: [romance_small_payments_by_country.sql](../sql/romance_small_payments_by_country.sql)
- Limit: this query showed only groups with at least 1,000 payments in each band. Receiving countries were not fixed individually. Zero observed labels does not mean impossible.

### R03 — Sending-country counts and rates tell different stories

Both recipient types combined:

| Sending code | Consumer-origin payments | Labels | Labels per 10,000 |
|---|---:|---:|---:|
| IN | 8,221 | 467 | 568.06 |
| CN | 47,741 | 435 | 91.12 |
| US | 307,379 | 130 | 4.23 |
| BR | 3,109 | 84 | 270.18 |
| ID | 1,494 | 74 | 495.31 |
| PK | 613 | 69 | 1,125.61 |
| NG | 3,631 | 67 | 184.52 |
| BD | 3,291 | 59 | 179.28 |

IN and CN together have **902 labels: 36.43% of all romance labels**, but only **2.63% of consumer-origin payments**.

Count means “how many labelled records?” Rate means “how common is the label within this group?” Both matter.

- SQL: [romance_labels_by_sending_country.sql](../sql/romance_labels_by_sending_country.sql)
- Check: totals matched 2,125,363 consumer payments and 2,476 romance labels.
- Limit: countries have different destination and recipient mixes. Tiny groups can have high but unstable rates.

### R04 — Particular sending–receiving pairs have strong concentrations

Consumer senders, both recipient types combined:

| Pair | Payments | Romance labels | Label percentage |
|---|---:|---:|---:|
| IN → CN | 428 | 66 | 15.42% |
| IN → EG | 56 | 52 | 92.86% |
| CN → EG | 69 | 49 | 71.01% |
| CN → CN | 2,473 | 38 | 1.54% |
| CN → IQ | 70 | 38 | 54.29% |
| CN → ID | 63 | 26 | 41.27% |
| CN → FR | 3,211 | 17 | 0.53% |
| CN → GB | 3,926 | 14 | 0.36% |

IN → CN had the most labels in the ranking, but some smaller pairs had higher rates.

**Meaning:** sending country alone hides important destination differences.

- SQL: [romance_labels_by_country_pair.sql](../sql/romance_labels_by_country_pair.sql), [romance_top_country_pairs.sql](../sql/romance_top_country_pairs.sql)
- Limit: pairs were selected using their labels in this same dataset. This is discovery, not proof of future detection performance. Some groups are small; repeated accounts or individual banks may explain the concentration.
- Output note: the full query returned 31,235 groups. Use the top-30 query for reading. The first uploaded full-output attachment contained only the zero-label tail, so it could not establish the leading pairs.

### R05 — Same-country bank pairs can also have labels

- CN → CN: **38 labels among 2,473 payments**.
- ID → ID: **16 labels among 16 payments**.

**Meaning:** reject any rule saying romance labels occur only between different bank countries. The 100% result is based on only 16 records.

- SQL: the country-pair files above.

**Revised romance rule:** romance labels are concentrated in particular bank-country pairs. The overall small-payment pattern does not hold in every country and recipient group. Amount alone is not enough to explain the labels.

**Chart idea:** show leading pair counts and rates together, with sample sizes. Add a small chart of countries where the under-$100 comparison reverses.

## 6. What we should not claim

- “Clients prefer this currency.” We measured use, not preference.
- “The sender has the same nationality as the bank country.”
- “Large payments are automatically scams.”
- “All romance labels involve small payments or different bank countries.”
- “NULL means verified legitimate.”
- “These countries are risky in real life.” This is fictitious data.
- “We have found the exact data-generation formula.”
- “Our detection rule works on new data.” We have not tested that.

Possible economic explanations must be labelled as possibilities. For example, business payments might involve larger obligations, but these summaries do not identify invoices, salaries or purchases.

## 7. Where to stop and what to do next

We have enough evidence to start building charts for currency, amounts and the romance-label investigation.

1. Check that the SQL files are saved and upload missing scripts.
2. Keep result tables with the scripts, especially the expensive P99 output.
3. Build charts from the small summaries, not all 10 million rows.
4. Check field and anomaly definitions in the official case documents.
5. Agree with Hui Min and Vincent which feature groups still need work: routes, duration, conversions, account/party details and other anomaly types.
6. Run another query only if it fills a clear gap, checks a contradiction or could change a conclusion.

A good finding has four parts: **what we saw, the numbers, how we tested it, and what we still do not know.**

This log is a working record, not the final submission. Treat related tests as supporting evidence for a few clear rules, rather than presenting every query as a separate insight.
