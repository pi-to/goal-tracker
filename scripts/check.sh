#!/usr/bin/env bash
# 公開前チェック: 構文と秘密情報の混入を検出する。
set -euo pipefail
cd "$(dirname "$0")/.."

python3 -m py_compile serve.py
python3 - <<'PY'
import pathlib, re, sys
root = pathlib.Path('.')
skip_dirs = {'.git', 'node_modules', 'public', '__pycache__', '.firebase'}
skip_files = {'cloud-config.json', 'scripts/check.sh'}
exts = {'.html', '.js', '.json', '.md', '.sh', '.py'}
key_re = re.compile(r'AIza[0-9A-Za-z_-]{20,}|G-[A-Z0-9]{8,}')
# 個人プロジェクト名は分割して保持（リポジトリ全文検索に載らないようにする）
slug = 'oz' + 'asa' + '-' + 'tomohiro'
bad = []
for p in root.rglob('*'):
    if not p.is_file():
        continue
    if any(part in skip_dirs for part in p.parts):
        continue
    if p.name in skip_files or p.suffix not in exts:
        continue
    text = p.read_text(encoding='utf-8', errors='ignore')
    if key_re.search(text) or slug in text:
        bad.append(str(p))
if bad:
    print('FAIL: 秘密情報または個人識別子:', ', '.join(bad), file=sys.stderr)
    sys.exit(1)
print('OK: 構文と秘密情報チェックを通過しました')
PY
