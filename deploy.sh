#!/usr/bin/env bash
# Firebase Hosting へ公開する。
# 必要: npx firebase-tools login
# 環境変数 FIREBASE_PROJECT にプロジェクトIDを入れる。
set -euo pipefail

cd "$(dirname "$0")"
: "${FIREBASE_PROJECT:?FIREBASE_PROJECT に Firebase プロジェクトIDを入れてください}"

if [[ ! -f .firebaserc ]]; then
  sed "s/YOUR_FIREBASE_PROJECT_ID/${FIREBASE_PROJECT}/" .firebaserc.example > .firebaserc
fi

mkdir -p public
cp goal_tracker.html public/index.html

# アプリは /cloud-config.json から firebaseConfig を読む。
# 無いとホスティング先で「この端末のみ」表示になり、Googleログインが出ない。
if [[ -f cloud-config.json ]]; then
  cp cloud-config.json public/cloud-config.json
else
  rm -f public/cloud-config.json
  echo "警告: cloud-config.json が無いため、公開先ではGoogleログインが出ません（アプリ内の設定で貼り付ければ使えます）" >&2
fi

npx --yes firebase-tools deploy --only hosting,firestore:rules --project "$FIREBASE_PROJECT"

echo
echo "公開URL: https://${FIREBASE_PROJECT}.web.app"
