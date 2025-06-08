# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## プロジェクト概要

Google Cloud Platform上に構築されたWebアナリティクスパイプラインで、完全なサーバーレスアナリティクスソリューションを実装しています：

- **フロントエンド**: Cloud Storage上でホストされる静的HTMLウェブサイト（リアルタイムイベント追跡機能付き）
- **API**: CORSが有効なイベント収集用Cloud Functions（第2世代）
- **ストレージ**: パーティション化とクラスタリングされたアナリティクスデータ用BigQueryテーブル
- **インフラ**: 再現可能なデプロイメント用の完全なTerraform設定

## アーキテクチャ

システムには2つの同じ実装があります：
- ルートレベル: 開発/テスト用ファイル（`index.js`, `index.html`）
- `function/`: 本番環境用Cloud Functionコード
- `terraform/`: 動的HTMLテンプレートを含むInfrastructure as Code

BigQueryスキーマ: `timestamp`, `event_type`, `user_id`, `session_id`, `url`, `properties` (JSON)
- クエリパフォーマンス向上のため`DATE(timestamp)`でパーティション化
- アナリティクス最適化のため`event_type`でクラスタリング

## 開発コマンド

### インフラ管理
```bash
# 完全なインフラをデプロイ
cd terraform
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvarsをプロジェクト詳細で編集
terraform init
terraform plan  
terraform apply

# 全リソースを削除
terraform destroy
# または包括的なクリーンアップスクリプトを使用
./scripts/cleanup.sh
```

### テストと検証
```bash
# Cloud Functionエンドポイントを直接テスト
curl -X POST "https://us-central1-{project}.cloudfunctions.net/track-event" \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "test_event",
    "user_id": "test_user", 
    "session_id": "test_session",
    "url": "https://example.com",
    "properties": {"test": true}
  }'

# 最近のイベントをBigQueryで検索
bq query --use_legacy_sql=false \
  "SELECT timestamp, event_type, user_id, session_id, url 
   FROM \`your-project.analytics.events\` 
   WHERE timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 1 HOUR) 
   ORDER BY timestamp DESC;"

# BigQueryテーブルを手動作成
bq query --use_legacy_sql=false < create_events_table.sql
```

### 手動GCPセットアップ
```bash
# 必要なAPIを有効化
gcloud services enable pubsub.googleapis.com bigquery.googleapis.com cloudfunctions.googleapis.com

# ファンクションを手動デプロイ
gcloud functions deploy track-event --runtime nodejs20 --trigger-http --allow-unauthenticated --entry-point trackEvent

# Webホスティングバケットをセットアップ
gsutil mb gs://your-analytics-project-web
gsutil web set -m index.html -e index.html gs://your-analytics-project-web
gsutil iam ch allUsers:objectViewer gs://your-analytics-project-web
```

## 主要な実装詳細

- Cloud FunctionはCORSプリフライトリクエストを処理し、適切なヘッダーを設定
- 両実装は同じBigQueryクライアントと挿入パターンを使用
- Terraformは実際のファンクションURLで動的HTMLを生成
- Propertiesフィールドは（文字列ではなく）BigQuery JSON型でJSONデータを保存
- ファンクションはデータ挿入に`@google-cloud/bigquery` v6.0.0を使用
- 全リソースは一貫した命名規則を使用: `{project-id}-web`, `{project-id}-function-source`

## プロジェクト構造
- `/function/`: package.json付きの本番環境用Cloud Function
- `/terraform/`: HTMLテンプレートとリソース作成を含む完全なIaC
- `/scripts/`: クリーンアップとメンテナンス用ユーティリティスクリプト
- ルート: 開発用ファイルとSQLスキーマ