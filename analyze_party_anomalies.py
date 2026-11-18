"""Stream Swift CSV with Decimal sums; optionally compare MySQL CSV exports.

python analyze_party_anomalies.py --source "C:/path/payments.csv" --output-dir evidence
Add --accounts for a second pass. Add --compare-dir sql_exports to verify queries 1-3.
No third-party packages needed. Inputs are read only; outputs go to output-dir.
"""
import argparse
import csv
from collections import Counter, defaultdict
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP
from pathlib import Path

ZERO = Decimal(0)


def label(value):
    value = (value or '').strip(' ').upper()
    return 'None' if value in ('', 'NONE') else value


def money(value):
    return format(value.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP), 'f')


def pct(numerator, denominator):
    if not denominator:
        return ''
    return format((Decimal(100) * numerator / denominator).quantize(
        Decimal('0.00001'), rounding=ROUND_HALF_UP), 'f')


def read_rows(source):
    with source.open(encoding='utf-8-sig', newline='') as handle:
        reader = csv.DictReader(handle)
        required = {'ANOMALY_TYPE', 'ORDERING_TYPE', 'BENEFICIARY_TYPE', 'USD_AMOUNT',
                    'ORDERING_ACCOUNT', 'BENEFICIARY_ACCOUNT'}
        if not required.issubset(reader.fieldnames or []):
            raise ValueError('CSV headers missing: ' + ', '.join(sorted(required - set(reader.fieldnames or []))))
        for index, row in enumerate(reader, 1):
            try:
                amount = Decimal(row['USD_AMOUNT'])
                if not amount.is_finite():
                    raise InvalidOperation
            except (InvalidOperation, TypeError):
                raise ValueError(f'Invalid or missing USD_AMOUNT at data row {index}') from None
            yield index, row, amount


def write_table(path, headers, records):
    with path.open('w', encoding='utf-8', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=headers)
        writer.writeheader()
        writer.writerows(records)


def compare(expected, actual, keys, fields):
    """Compare unformatted Workbench exports by keys, not row order."""
    def load(path):
        with path.open(encoding='utf-8-sig', newline='') as handle:
            result = {}
            for row in csv.DictReader(handle):
                key = tuple(row[k] for k in keys)
                if key in result:
                    raise ValueError(f'Duplicate comparison key in {path}: {key}')
                result[key] = row
            return result
    left, right = load(expected), load(actual)
    if left.keys() != right.keys():
        raise ValueError(f'Key mismatch: {actual.name}')
    for key, row in left.items():
        for field in fields:
            a, b = row[field], right[key][field]
            if a == '' and b.upper() in ('', 'NULL', '\\N'):
                continue
            if Decimal(a) != Decimal(b):
                raise ValueError(f'Mismatch in {actual.name}: {key}, {field}: {a} vs {b}')


def run(source, output, accounts=False, compare_dir=None):
    if not source.is_file():
        raise FileNotFoundError(source)
    counts = Counter()
    amounts = defaultdict(Decimal)
    pair_counts = Counter()
    pair_amounts = defaultdict(Decimal)
    account_labels = Counter()
    quality = Counter()
    for index, row, amount in read_rows(source):
        anomaly = label(row['ANOMALY_TYPE'])
        counts[anomaly] += 1
        amounts[anomaly] += amount
        pair = (row['ORDERING_TYPE'], row['BENEFICIARY_TYPE'])
        if pair[0] in ('B', 'C') and pair[1] in ('B', 'C'):
            pair_counts[(pair, anomaly)] += 1
            pair_amounts[(pair, anomaly)] += amount
        else:
            quality['excluded_non_BC_rows'] += 1
        quality['zero_amount_rows'] += amount == 0
        quality['negative_amount_rows'] += amount < 0
        if accounts and anomaly != 'None':
            for role, field in [('Ordering', 'ORDERING_ACCOUNT'), ('Beneficiary', 'BENEFICIARY_ACCOUNT')]:
                account = row[field]
                if account is not None and account.strip(' '):
                    account_labels[(role, account, anomaly)] += 1
        if index % 1_000_000 == 0:
            print(f'First pass: {index:,} rows', flush=True)
    total_n, total_usd = sum(counts.values()), sum(amounts.values(), ZERO)
    labelled_usd = sum((v for k, v in amounts.items() if k != 'None'), ZERO)
    profiles = []
    for anomaly in sorted(counts, key=lambda k: (-counts[k], k)):
        profiles.append(dict(anomaly_type=anomaly, payment_count=counts[anomaly],
            payment_share_pct=pct(Decimal(counts[anomaly]), Decimal(total_n)),
            usd_amount=money(amounts[anomaly]),
            share_of_all_payment_value_pct=pct(amounts[anomaly], total_usd),
            share_of_labelled_payment_value_pct='' if anomaly == 'None' else pct(amounts[anomaly], labelled_usd)))
    pairs, labels = [], []
    for pair in sorted({k[0] for k in pair_counts}):
        keys = [k for k in pair_counts if k[0] == pair]
        n = sum(pair_counts[k] for k in keys)
        labelled_n = sum(pair_counts[k] for k in keys if k[1] != 'None')
        name = '->'.join(pair)
        pairs.append(dict(party_pair=name, payment_count=n, labelled_payment_count=labelled_n,
            labelled_rate_pct=pct(Decimal(labelled_n), Decimal(n)),
            labelled_usd_amount=money(sum((pair_amounts[k] for k in keys if k[1] != 'None'), ZERO))))
        for key in sorted(keys):
            labels.append(dict(party_pair=name, anomaly_type=key[1], payment_count=pair_counts[key],
                pair_payment_count=n, label_rate_pct=pct(Decimal(pair_counts[key]), Decimal(n)),
                usd_amount=money(pair_amounts[key])))
    output.mkdir(parents=True, exist_ok=True)
    tables = [('label_profile.csv', profiles, ['anomaly_type']),
              ('party_pair_profile.csv', pairs, ['party_pair']),
              ('party_pair_labels.csv', labels, ['party_pair', 'anomaly_type'])]
    for name, records, keys in tables:
        if not records:
            raise ValueError(f'No rows for {name}; check source and B/C codes')
        headers = list(records[0])
        write_table(output / name, headers, records)
        if compare_dir:
            compare(output / name, compare_dir / name, keys, [h for h in headers if h not in keys])
    quality['total_rows'] = total_n
    quality['labelled_rows'] = sum(v for k, v in counts.items() if k != 'None')
    write_table(output / 'quality_counts.csv', ['check', 'row_count'],
                [dict(check=k, row_count=v) for k, v in sorted(quality.items())])
    if accounts:
        selected = {(role, account) for role, account, _ in account_labels}
        histories, history_amounts = Counter(), defaultdict(Decimal)
        for index, row, amount in read_rows(source):
            for role, field in [('Ordering', 'ORDERING_ACCOUNT'), ('Beneficiary', 'BENEFICIARY_ACCOUNT')]:
                key = (role, row[field])
                if key in selected:
                    histories[key] += 1
                    history_amounts[key] += amount
            if index % 1_000_000 == 0:
                print(f'Second pass: {index:,} rows', flush=True)
        records = []
        for (role, account, anomaly), n in sorted(account_labels.items(), key=lambda x: (-x[1], x[0])):
            key = (role, account)
            records.append(dict(account_role=role, account=account, anomaly_type=anomaly,
                label_payment_count=n, account_payment_count=histories[key],
                label_rate_pct=pct(Decimal(n), Decimal(histories[key])),
                all_usd_amount=money(history_amounts[key])))
        write_table(output / 'account_label_history.csv',
            ['account_role', 'account', 'anomaly_type', 'label_payment_count',
             'account_payment_count', 'label_rate_pct', 'all_usd_amount'], records)
    print(f'Wrote evidence for {total_n:,} rows to {output}')
    if compare_dir:
        print('PASS: all three SQL summary exports match the Python outputs.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', required=True, type=Path)
    parser.add_argument('--output-dir', type=Path, default=Path('party_evidence'))
    parser.add_argument('--accounts', action='store_true')
    parser.add_argument('--compare-dir', type=Path)
    args = parser.parse_args()
    if args.compare_dir and args.compare_dir.resolve() == args.output_dir.resolve():
        parser.error('SQL exports and Python outputs must use different folders')
    run(args.source, args.output_dir, args.accounts, args.compare_dir)
