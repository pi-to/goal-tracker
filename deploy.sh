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

npx --yes firebase-tools deploy --only hosting,firestore:rules --project "$FIREBASE_PROJECT"

echo
echo "公開URL: https://${FIREBASE_PROJECT}.web.app"
