#!/usr/bin/env python3
"""normalize_getchallenge.py

Backs up getchallenge.csv then normalizes it by:
- removing all double-quote characters (")
- removing BOM (\ufeff)
- trimming whitespace around each field
- ensuring there is a header with expected columns if missing

Usage: python3 normalize_getchallenge.py [path/to/getchallenge.csv]
"""
import sys
import os
import time

INPUT = sys.argv[1] if len(sys.argv) > 1 else "getchallenge.csv"
if not os.path.isfile(INPUT):
    print(f"File not found: {INPUT}")
    sys.exit(1)

# Backup with timestamp
bak = f"{INPUT}.bak.{int(time.time())}"
try:
    os.replace(INPUT, bak)
    print(f"Backed up {INPUT} -> {bak}")
except Exception as e:
    print(f"Failed to create backup: {e}")
    sys.exit(1)

out_lines = []
with open(bak, 'r', encoding='utf-8', errors='replace') as f:
    for line in f:
        # remove BOM if present and strip newline
        line = line.replace('\ufeff', '').rstrip('\r\n')
        # remove all double quotes
        line = line.replace('"', '')
        # split on comma, strip whitespace for each field
        parts = [p.strip() for p in line.split(',')]
        out_lines.append(','.join(parts))

# Ensure header exists and has expected columns
expected_header = 'challenge_id,difficulty,no_pre_mine,no_pre_mine_hour,latest_submission'
if len(out_lines) == 0:
    print('Input file empty after processing')
    sys.exit(1)

first = out_lines[0].lower()
if 'challenge_id' not in first:
    # assume original had no header; add expected header
    out_lines.insert(0, expected_header)
    print('Added header to CSV')
else:
    # normalize header to expected (remove quotes already done)
    # replace header line with expected if it contains at least 3 of the expected fields
    hdr_fields = set([x.strip() for x in first.split(',') if x.strip()])
    exp_fields = set(expected_header.split(','))
    if len(hdr_fields & exp_fields) >= 3:
        # replace with canonical header ordering
        out_lines[0] = expected_header
        print('Normalized header to canonical ordering')

# Write back to original path
try:
    with open(INPUT, 'w', encoding='utf-8', newline='') as f:
        for l in out_lines:
            f.write(l + '\n')
    print(f'Wrote normalized CSV to {INPUT}')
except Exception as e:
    print(f'Failed to write normalized file: {e}')
    # Attempt to restore backup
    try:
        os.replace(bak, INPUT)
        print('Restored backup due to failure')
    except Exception as re:
        print('Failed to restore backup:', re)
    sys.exit(1)

print('Done.')
