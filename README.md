# 目標トラッカー

**アプリをブラウザで見るURL（こちらを開く）:** [https://pi-to.github.io/goal-tracker/](https://pi-to.github.io/goal-tracker/)

[github.com/pi-to/goal-tracker](https://github.com/pi-to/goal-tracker) はソースコードの置き場です。リポジトリを開いても画面は動きません。

個人のゴール（平凡 → PL）、資産・年収、習慣KPI、週次・月次の振り返り、カレンダーを1ファイルの Web アプリで記録します。

データは端末の `localStorage` に保存し、任意で **Google ログイン + Firestore** に同期します。ユーザーごとに文書が分かれるため、複数人が同じアプリを使っても他人のデータは見えません。

## 個人情報・秘密情報

このリポジトリには **Firebase の API キー、プロジェクトID、個人名、実データは含まれません。**

| 含めるもの | 含めないもの |
|---|---|
| アプリ本体 `goal_tracker.html` | `cloud-config.json`（実キー） |
| `cloud-config.example.json` | `.firebaserc`（実プロジェクト） |
| Firestore ルール（自分の UID のみ） | `public/index.html`（デプロイ生成物） |

公開前に必ずチェックしてください。

```bash
chmod +x scripts/check.sh deploy.sh
./scripts/check.sh
```

実キーがソースに残っていると失敗します。

## 必要環境

- Python 3.9 以上（標準ライブラリのみ。`pip install` は不要）
- ブラウザ（Chrome / Safari / Firefox）
- クラウド同期する場合: Firebase プロジェクト（Spark 無料で可）、Node.js 18+（デプロイ時のみ）

## ローカルで動かす（再現手順）

```bash
git clone https://github.com/pi-to/goal-tracker.git
cd goal-tracker
python3 serve.py
```

ブラウザで http://127.0.0.1:8080/goal_tracker.html を開きます。

この状態ではログインなしで使えます。記録はブラウザ内だけに残ります。

## クラウド同期（任意）

1. [Firebase Console](https://console.firebase.google.com/) でプロジェクトを作成する（無料 Spark で可）。
2. Authentication → Sign-in method → **Google** を有効にする。
3. Firestore Database を作成する。
4. ウェブアプリを追加し、`firebaseConfig` をコピーする。
5. `cloud-config.example.json` を `cloud-config.json` にコピーし、値を書き換える。**このファイルはコミットしない。**
6. Firestore の Rules を `firestore.rules` の内容に置き換える。
7. Authentication → Settings → Authorized domains に、アプリのホスト名を追加する（`https://` は付けない）。
   - ローカル: `localhost`
   - Hosting: `YOUR_PROJECT_ID.web.app` と `YOUR_PROJECT_ID.firebaseapp.com`
8. `python3 serve.py` を再起動し、ページを再読み込みして「Googleでログイン」する。

アプリ内の「設定」に `firebaseConfig` を貼っても同じです。

## GitHub Pages（このリポジトリから公開）

Settings → Pages で `main` ブランチの `/` を公開済みです。初回は数分かかることがあります。

- トップ: https://pi-to.github.io/goal-tracker/
- 本体: https://pi-to.github.io/goal-tracker/goal_tracker.html

Google ログインを使う場合は、Firebase の Authorized domains に `pi-to.github.io` を追加してください。

## Firebase Hosting への公開（固定URL）

GitHub Pages（上の `github.io` URL）ですでにアプリは公開されています。Hosting は任意です。

```bash
cp .firebaserc.example .firebaserc   # default を自分のプロジェクトIDに変更
export FIREBASE_PROJECT=YOUR_PROJECT_ID
npx firebase-tools login
./deploy.sh
```

公開URLは `https://YOUR_PROJECT_ID.web.app` です。トンネルは使いません。

`deploy.sh` は `cloud-config.json` があれば `public/cloud-config.json` として一緒に公開します。アプリはこれを読んで Google ログインを出すため、無いと公開先で「この端末のみ」表示になります。`public/` はコミットしません。

Hosting で「Googleでログイン」が出ない、または `auth/unauthorized-domain` になるときは、Authentication → Settings → Authorized domains に次を追加してください。

- `YOUR_PROJECT_ID.web.app`
- `YOUR_PROJECT_ID.firebaseapp.com`

### ヘッドレス環境（ブラウザが開かないとき）

`firebase login --no-localhost` を使う。画面に **2種類の値** が出る。

| 項目 | 例 | 貼る場所 |
|---|---|---|
| session ID | `62ABD`（短い英数字） | 貼らない。ブラウザ側の照合用 |
| authorization code | `4/0A...` のような長い文字列 | CLI の `Enter authorization code` に貼る |

手順:

1. `npx firebase-tools logout`（以前の失敗が残っている場合）
2. `npx firebase-tools login --no-localhost`
3. 表示された **URL全体** を別端末のブラウザで開く（session ID だけを開くのではない）
4. Google で許可したあと、ページに出る **長い認可コード** をコピーする
5. ターミナルの `Enter authorization code` にその長いコードを貼る

`session ID`（例: `62ABD`）を認可コード欄に貼ると `Unable to authenticate using the provided code` になる。

それでも失敗する場合:

- `npx firebase-tools login --no-localhost --debug` で `Premature close` が出ていないか確認する
- Node.js 22 系（例: 22.16）でやり直す。24.17 以降はトークン交換が壊れることがある
- ブラウザがある PC で `npx firebase-tools login:ci` を実行し、表示されたトークンを **チャットに貼らず** 自分の環境だけに `export FIREBASE_TOKEN=...` してから `./deploy.sh`

認可コードも `FIREBASE_TOKEN` も他人に送らない。

## ディレクトリ

```
goal_tracker.html          アプリ本体（HTML/CSS/JS）
serve.py                   ローカル用 HTTP サーバ（cloud-config.json の保存も担当）
firestore.rules            ユーザーごとの読み書き制限
firebase.json              Hosting / Rules の定義
cloud-config.example.json  設定のひな形（実キーなし）
.firebaserc.example        プロジェクトIDのひな形
deploy.sh                  Hosting デプロイ
scripts/check.sh           秘密情報混入チェック
```

## データの扱い

- 未ログイン: そのブラウザの `localStorage` のみ
- ログイン後: Firestore `users/{uid}` に JSON 1件。ルール上、本人以外は読めない
- リポジトリにはユーザーの記録は置かない
