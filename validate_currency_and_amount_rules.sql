-- Additional-country checks: MySQL 8, read-only. Run one query at a time.
-- Source: swift_datathon.swift_payments. These are additional-country checks,
-- not independent holdouts: the records were in the earlier overall summaries.
USE swift_datathon;

-- 1. Currency shares by origin and US/non-US receiving bank.
-- Export as validation_currency_new_countries.csv.
WITH checked AS (
 SELECT SUBSTRING(ordering_bic8,5,2) AS sending_country,
 CASE WHEN SUBSTRING(beneficiary_bic8,5,2)='US'
      THEN 'US receiving bank' ELSE 'Non-US receiving bank' END AS receiving_group,
 CASE SUBSTRING(ordering_bic8,5,2)
      WHEN 'AU' THEN 'AUD' WHEN 'CA' THEN 'CAD' WHEN 'JP' THEN 'JPY' END AS local_currency,
 currency_code
 FROM swift_payments
 WHERE CHAR_LENGTH(ordering_bic8)=8 AND CHAR_LENGTH(beneficiary_bic8)=8
 AND SUBSTRING(ordering_bic8,5,2) IN ('AU','CA','JP')
 AND NULLIF(TRIM(currency_code),'') IS NOT NULL
)
SELECT sending_country, receiving_group, local_currency, COUNT(*) AS payment_count,
 SUM(currency_code=local_currency) AS local_currency_count,
 ROUND(100.0*AVG(currency_code=local_currency),2) AS local_currency_share_pct,
 SUM(currency_code='USD') AS usd_count,
 ROUND(100.0*AVG(currency_code='USD'),2) AS usd_share_pct
FROM checked GROUP BY sending_country,receiving_group,local_currency
ORDER BY sending_country,receiving_group;

-- 2. Amount thresholds within fixed origin/destination pairs.
-- Export as validation_amount_new_pairs.csv. B=business, C=consumer.
-- Amounts are expressed in USD, regardless of the payment currency.
SELECT SUBSTRING(ordering_bic8,5,2) AS sending_country,
 SUBSTRING(beneficiary_bic8,5,2) AS receiving_country,
 CONCAT(ordering_type,' to ',beneficiary_type) AS customer_group,
 COUNT(*) AS payment_count,
 ROUND(100.0*AVG(usd_amount>=1000),2) AS share_at_least_1000_pct,
 ROUND(100.0*AVG(usd_amount>=10000),2) AS share_at_least_10000_pct,
 ROUND(100.0*AVG(usd_amount>=100000),2) AS share_at_least_100000_pct
FROM swift_payments
WHERE CHAR_LENGTH(ordering_bic8)=8 AND CHAR_LENGTH(beneficiary_bic8)=8
 AND SUBSTRING(ordering_bic8,5,2) IN ('AU','CA','JP')
 AND SUBSTRING(beneficiary_bic8,5,2)='US'
 AND ordering_type IN ('B','C') AND beneficiary_type IN ('B','C')
 AND usd_amount>0
GROUP BY SUBSTRING(ordering_bic8,5,2),SUBSTRING(beneficiary_bic8,5,2),
 ordering_type,beneficiary_type
ORDER BY sending_country,FIELD(ordering_type,'B','C'),FIELD(beneficiary_type,'B','C');
