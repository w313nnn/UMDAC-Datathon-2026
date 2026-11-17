"""Stream the original 10m-row Swift CSV and write Vincent's evidence tables.

Run with the bundled Python runtime after placing the organizer CSV at SOURCE.
The output figures reconcile to the matching MySQL queries in party_anomalies.sql.
"""
from collections import Counter
from pathlib import Path
import csv

SOURCE = Path(r"C:\Users\Vincent\Downloads\swift_umdac_datathon_2026_fictitious_payment_data\swift_umdac_datathon_2026_fictitious_payment_data.csv")
OUTPUT = Path("party_anomaly_summary.csv")

rows = Counter()
amounts = Counter()
account_labels = Counter()
labelled_accounts = set()

with SOURCE.open(encoding="utf-8-sig", newline="") as handle:
    reader = csv.DictReader(handle)
    for index, row in enumerate(reader, start=1):
        anomaly = row["ANOMALY_TYPE"] or "None"
        party_pair = f"{row['ORDERING_TYPE']}→{row['BENEFICIARY_TYPE']}"
        amount = float(row["USD_AMOUNT"])
        key = (party_pair, anomaly)
        rows[key] += 1
        amounts[key] += amount
        if anomaly != "None":
            for role, account in (("Ordering", row["ORDERING_ACCOUNT"]), ("Beneficiary", row["BENEFICIARY_ACCOUNT"])):
                account_key = (role, account)
                labelled_accounts.add(account_key)
                account_labels[(role, account, anomaly)] += 1
        if index % 1_000_000 == 0:
            print(f"first pass processed {index:,}", flush=True)

# Second pass obtains complete histories only for accounts seen in labelled rows.
account_all = Counter()
account_amounts = Counter()
with SOURCE.open(encoding="utf-8-sig", newline="") as handle:
    reader = csv.DictReader(handle)
    for index, row in enumerate(reader, start=1):
        amount = float(row["USD_AMOUNT"])
        for role, account in (("Ordering", row["ORDERING_ACCOUNT"]), ("Beneficiary", row["BENEFICIARY_ACCOUNT"])):
            account_key = (role, account)
            if account_key in labelled_accounts:
                account_all[account_key] += 1
                account_amounts[account_key] += amount
        if index % 1_000_000 == 0:
            print(f"second pass processed {index:,}", flush=True)

with OUTPUT.open("w", newline="", encoding="utf-8") as handle:
    writer = csv.writer(handle)
    writer.writerow(["section", "party_pair", "anomaly_type", "payment_count", "usd_amount"])
    for (pair, anomaly), count in sorted(rows.items()):
        writer.writerow(["party_pair", pair, anomaly, count, f"{amounts[(pair, anomaly)]:.2f}"])
    writer.writerow([])
    writer.writerow(["section", "role", "account", "anomaly_type", "labelled_payments", "all_payments", "all_usd_amount"])
    ranked = sorted(account_labels.items(), key=lambda item: item[1], reverse=True)[:50]
    for (role, account, anomaly), labelled in ranked:
        account_key = (role, account)
        writer.writerow(["top_account", role, account, anomaly, labelled, account_all[account_key], f"{account_amounts[account_key]:.2f}"])

print(f"Wrote {OUTPUT}")
