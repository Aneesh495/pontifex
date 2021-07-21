#!/usr/bin/env bash
set -euo pipefail

echo "================================================================================"
echo "PONTIFEX CODEBASE SCALE & METRIC REPORT"
echo "================================================================================"

python3 -c "
import os

stats = {}
file_counts = {}

for root, dirs, files in os.walk('.'):
    if any(p in root for p in ['.git', '.terraform', '.generated', 'bin']):
        continue
    for f in files:
        ext = os.path.splitext(f)[1]
        if f.endswith('.tftest.hcl'):
            ext = 'HCL (Test Suites)'
        elif ext in ['.tf', '.tofu']:
            ext = 'HCL (Infrastructure)'
        elif ext == '.hcl':
            ext = 'HCL (Lock & Config)'
        elif ext == '.go':
            ext = 'Go (CLI & Verifier)'
        elif ext == '.md':
            ext = 'Markdown (Documentation)'
        elif ext == '.sh':
            ext = 'Shell (Automation)'
        elif ext in ['.example', '.tfvars']:
            ext = 'HCL (Variable Manifests)'
        else:
            continue

        p = os.path.join(root, f)
        try:
            with open(p, 'r', encoding='utf-8', errors='ignore') as fp:
                lines = len(fp.readlines())
                stats[ext] = stats.get(ext, 0) + lines
                file_counts[ext] = file_counts.get(ext, 0) + 1
        except Exception:
            pass

total_lines = sum(stats.values())
hcl_lines = sum(v for k, v in stats.items() if 'HCL' in k)

print(f'{'Language / Layer':32} | {'Files':6} | {'Lines':8}')
print('-' * 52)
for k, v in sorted(stats.items(), key=lambda x: -x[1]):
    print(f'{k:32} | {file_counts[k]:6} | {v:8}')
print('-' * 52)
print(f'{'TOTAL CODEBASE':32} | {sum(file_counts.values()):6} | {total_lines:8}')
print(f'{'TOTAL HCL CORE':32} | {sum(file_counts[k] for k in file_counts if \"HCL\" in k):6} | {hcl_lines:8}')
"

echo "================================================================================"
