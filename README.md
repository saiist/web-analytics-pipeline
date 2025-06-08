# Google Cloud上のWebアナリティクスパイプライン

このプロジェクトは、Google Cloud Platformサービスを使用した完全なWebアナリティクスパイプラインを実装しています。

## アーキテクチャ

- **フロントエンド**: Cloud Storage上でホストされる静的HTMLウェブサイト
- **API**: イベント収集用のCloud Functions（第2世代）
- **ストレージ**: パーティション化とクラスタリングを備えたアナリティクスデータ用BigQuery
- **インフラ**: Infrastructure as Code用のTerraform

## コンポーネント

### 1. BigQuery
- データセット: `analytics`
- テーブル: `events`（日付でパーティション化、event_typeでクラスタリング）
- スキーマ: timestamp, event_type, user_id, session_id, url, properties

### 2. Cloud Functions
- ファンクション: `track-event`
- ランタイム: Node.js 20
- クロスオリジンリクエスト用にCORSを有効化
- パブリックアクセス可能

### 3. Cloud Storage
- バケット: `{project-id}-web`（ウェブサイトホスティング）
- バケット: `{project-id}-function-source`（ファンクションコード）

## クイックスタート

### 事前準備

1. Google Cloud認証を設定:
```bash
# 認証方法を確認
make auth

# Application Default Credentials（推奨）
gcloud auth application-default login

# またはgcloud認証
gcloud auth login
```

### Makefileを使用（推奨）

```bash
# 依存関係を確認
make check-deps

# Terraformを初期化
make init

# terraform.tfvarsファイルを設定
cd terraform
cp terraform.tfvars.example terraform.tfvars
# プロジェクト詳細を編集
cd ..

# 完全なインフラをデプロイ
make deploy

# Cloud Functionをテスト
make test PROJECT_ID=your-project-id
```

### Terraformを直接使用

1. セットアップ:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# プロジェクト詳細でterraform.tfvarsを編集
```

2. デプロイ:
```bash
terraform init
terraform plan
terraform apply
```

### 手動デプロイメント

1. プロジェクトを作成してAPIを有効化:
```bash
gcloud projects create your-analytics-project
gcloud services enable pubsub.googleapis.com bigquery.googleapis.com cloudfunctions.googleapis.com
```

2. BigQueryリソースを作成:
```bash
bq mk --dataset --location=US your-analytics-project:analytics
bq query --use_legacy_sql=false < create_events_table.sql
```

3. Cloud Functionをデプロイ:
```bash
gcloud functions deploy track-event --runtime nodejs20 --trigger-http --allow-unauthenticated --entry-point trackEvent
```

4. Webホスティングをセットアップ:
```bash
gsutil mb gs://your-analytics-project-web
gsutil web set -m index.html -e index.html gs://your-analytics-project-web
gsutil iam ch allUsers:objectViewer gs://your-analytics-project-web
gsutil cp index.html gs://your-analytics-project-web/
```

## 使用方法

1. ウェブサイトにアクセス: `https://storage.googleapis.com/{bucket-name}/index.html`
2. ボタンをクリックしてイベントを生成
3. イベントがCloud Functionsに送信され、BigQueryに保存される
4. アナリティクスデータをBigQueryでクエリ

## テスト

### Makefileを使用
```bash
# Cloud Functionをテスト
make test PROJECT_ID=your-project-id
```

### 手動でAPIをテスト
```bash
curl -X POST "https://us-central1-{project}.cloudfunctions.net/track-event" \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "test_event",
    "user_id": "test_user",
    "session_id": "test_session",
    "url": "https://example.com",
    "properties": {"test": true}
  }'
```

データをクエリ:
```sql
SELECT 
  timestamp,
  event_type,
  user_id,
  session_id,
  url
FROM `your-project.analytics.events`
WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR)
ORDER BY timestamp DESC;
```

## クリーンアップ

### Makefileを使用
```bash
# 全リソースを削除
make destroy

# 一時ファイルのみを削除
make clean

# 完全なクリーンアップ（リソース削除 + 一時ファイル削除）
make clean-all
```

### 手動でクリーンアップ
```bash
# Terraformを使用
terraform destroy

# または包括的なクリーンアップスクリプトを使用
./scripts/cleanup.sh
```

## 利用可能なMakeコマンド

```bash
make help           # 利用可能なコマンドを表示
make auth           # Google Cloud認証の設定方法を表示
make check-deps     # 依存関係をチェック
make init           # Terraformを初期化
make deploy         # 完全なインフラをデプロイ
make destroy        # 全リソースを削除
make test           # Cloud Functionをテスト
make function-deploy # Cloud Functionのみをデプロイ
make bq-setup       # BigQueryリソースを手動作成
make web-deploy     # Webサイトのみをデプロイ
make clean          # 一時ファイルを削除
```