# Web Analytics Pipeline Makefile
# このMakefileはGoogle Cloud上のWebアナリティクスパイプラインの開発とデプロイを支援します

.PHONY: help auth check-deps init deploy destroy test clean function-deploy function-test bq-setup web-deploy

# デフォルトターゲット
help:
	@echo "利用可能なコマンド:"
	@echo "  auth           - Google Cloud認証の設定方法を表示"
	@echo "  check-deps     - 依存関係をチェック"
	@echo "  init           - Terraformの初期化"
	@echo "  deploy         - 完全なインフラをデプロイ"
	@echo "  destroy        - 全リソースを削除"
	@echo "  test           - Cloud Functionをテスト"
	@echo "  function-deploy- Cloud Functionのみをデプロイ"
	@echo "  function-test  - ローカルでCloud Functionをテスト"
	@echo "  bq-setup       - BigQueryリソースを手動作成"
	@echo "  web-deploy     - Webサイトのみをデプロイ"
	@echo "  clean          - 一時ファイルを削除"

# 依存関係のチェック
check-deps:
	@echo "依存関係をチェック中..."
	@which terraform >/dev/null || (echo "Error: terraform がインストールされていません" && exit 1)
	@which gcloud >/dev/null || (echo "Error: gcloud CLI がインストールされていません" && exit 1)
	@which bq >/dev/null || (echo "Error: bq CLI がインストールされていません" && exit 1)
	@which gsutil >/dev/null || (echo "Error: gsutil がインストールされていません" && exit 1)
	@echo "✅ 全依存関係が利用可能です"

# 認証ファイルの自動検出
CREDENTIALS_FILE := $(shell if [ -f ~/terraform-key.json ]; then echo ~/terraform-key.json; elif [ -f ~/.config/gcloud/application_default_credentials.json ]; then echo ~/.config/gcloud/application_default_credentials.json; else echo ""; fi)

# 認証付きコマンド実行のヘルパー
define run_with_auth
	@if [ -n "$(CREDENTIALS_FILE)" ]; then \
		echo "認証ファイルを使用: $(CREDENTIALS_FILE)"; \
		cd $(1) && GOOGLE_APPLICATION_CREDENTIALS="$(CREDENTIALS_FILE)" $(2); \
	else \
		echo "Warning: 認証ファイルが見つかりません"; \
		cd $(1) && $(2); \
	fi
endef

define require_auth
	@if [ -z "$(CREDENTIALS_FILE)" ]; then \
		echo "Error: 認証ファイルが見つかりません。'make auth'を実行してください"; \
		exit 1; \
	fi
endef

# Google Cloud認証の設定
auth:
	@echo "Google Cloud認証を設定中..."
	@if [ -n "$(CREDENTIALS_FILE)" ]; then \
		echo "✅ 認証ファイルが見つかりました: $(CREDENTIALS_FILE)"; \
	else \
		echo "❌ 認証ファイルが見つかりません"; \
		echo "以下のコマンドのいずれかを実行してください:"; \
		echo "1. Application Default Credentials (推奨):"; \
		echo "   gcloud auth application-default login"; \
		echo "2. gcloud認証:"; \
		echo "   gcloud auth login"; \
		echo "3. サービスアカウントキー:"; \
		echo "   gcloud iam service-accounts keys create ~/terraform-key.json --iam-account=terraform-service@$(shell gcloud config get-value project).iam.gserviceaccount.com"; \
	fi

# Terraformの初期化
init: check-deps
	@echo "Terraformを初期化中..."
	$(call run_with_auth,terraform,terraform init)

# terraform.tfvarsファイルの存在確認
terraform/terraform.tfvars:
	@echo "terraform.tfvarsファイルが見つかりません"
	@echo "以下のコマンドでファイルを作成してください:"
	@echo "  cd terraform && cp terraform.tfvars.example terraform.tfvars"
	@echo "その後、プロジェクト詳細を編集してください"
	@exit 1

# 完全なインフラデプロイ
deploy: init terraform/terraform.tfvars
	@echo "インフラをデプロイ中..."
	$(call require_auth)
	$(call run_with_auth,terraform,terraform plan)
	$(call run_with_auth,terraform,terraform apply -auto-approve)

# 全リソース削除
destroy: terraform/terraform.tfvars
	@echo "全リソースを削除中..."
	@echo "注意: BigQueryテーブルの削除保護を無効化してから削除します"
	$(call require_auth)
	$(call run_with_auth,terraform,terraform apply -auto-approve -var="deletion_protection=false" || true)
	$(call run_with_auth,terraform,terraform destroy -auto-approve)

# Cloud Functionのテスト
test:
	@echo "Cloud Functionをテスト中..."
	@if [ -z "$(PROJECT_ID)" ]; then \
		echo "Error: PROJECT_ID環境変数を設定してください"; \
		echo "例: make test PROJECT_ID=your-project-id"; \
		exit 1; \
	fi
	curl -X POST "https://us-central1-$(PROJECT_ID).cloudfunctions.net/track-event" \
		-H "Content-Type: application/json" \
		-d '{"event_type": "test_event", "user_id": "test_user", "session_id": "test_session", "url": "https://example.com", "properties": {"test": true}}'

# Cloud Functionのみをデプロイ（手動）
function-deploy: check-deps
	@echo "Cloud Functionをデプロイ中..."
	@if [ -z "$(PROJECT_ID)" ]; then \
		echo "Error: PROJECT_ID環境変数を設定してください"; \
		echo "例: make function-deploy PROJECT_ID=your-project-id"; \
		exit 1; \
	fi
	$(call run_with_auth,.,gcloud config set project $(PROJECT_ID))
	$(call run_with_auth,function,gcloud functions deploy track-event --runtime nodejs20 --trigger-http --allow-unauthenticated --entry-point trackEvent)

# ローカルでCloud Functionをテスト
function-test:
	@echo "ローカルでCloud Functionをテスト中..."
	cd function && npm install
	@echo "注意: ローカルテストにはFunctions Frameworkが必要です"
	@echo "インストール: npm install -g @google-cloud/functions-framework"

# BigQueryリソースを手動作成
bq-setup: check-deps
	@echo "BigQueryリソースを作成中..."
	@if [ -z "$(PROJECT_ID)" ]; then \
		echo "Error: PROJECT_ID環境変数を設定してください"; \
		echo "例: make bq-setup PROJECT_ID=your-project-id"; \
		exit 1; \
	fi
	$(call run_with_auth,.,bq mk --dataset --location=US $(PROJECT_ID):analytics)
	$(call run_with_auth,.,bq query --use_legacy_sql=false < create_events_table.sql)

# Webサイトのみをデプロイ（手動）
web-deploy: check-deps
	@echo "Webサイトをデプロイ中..."
	@if [ -z "$(PROJECT_ID)" ]; then \
		echo "Error: PROJECT_ID環境変数を設定してください"; \
		echo "例: make web-deploy PROJECT_ID=your-project-id"; \
		exit 1; \
	fi
	$(call run_with_auth,.,gsutil mb gs://$(PROJECT_ID)-web || echo "バケットは既に存在します")
	$(call run_with_auth,.,gsutil web set -m index.html -e index.html gs://$(PROJECT_ID)-web)
	$(call run_with_auth,.,gsutil iam ch allUsers:objectViewer gs://$(PROJECT_ID)-web)
	$(call run_with_auth,.,gsutil cp index.html gs://$(PROJECT_ID)-web/)

# 一時ファイルの削除
clean:
	@echo "一時ファイルを削除中..."
	rm -f terraform/function-source.zip
	rm -f terraform/.terraform.lock.hcl
	rm -rf terraform/.terraform/
	@echo "✅ クリーンアップ完了"

# 完全なクリーンアップ（リソース削除）
clean-all: destroy clean
	@echo "完全なクリーンアップを実行中..."
	./scripts/cleanup.sh