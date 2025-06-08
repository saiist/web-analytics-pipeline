#!/bin/bash

# GCP Resource Cleanup Script
# This script deletes all resources created for the analytics pipeline

set -e

PROJECT_ID="your-analytics-project"
REGION="us-central1"

echo "🗑️  Starting cleanup of GCP resources for project: $PROJECT_ID"
echo "This will delete ALL resources. Press Ctrl+C to cancel..."
sleep 5

# Set project
echo "Setting project to $PROJECT_ID..."
gcloud config set project $PROJECT_ID

# 1. Delete Cloud Functions
echo "🔥 Deleting Cloud Functions..."
gcloud functions delete track-event --region=$REGION --quiet || echo "Cloud Function already deleted or not found"

# 2. Delete Cloud Storage buckets
echo "🗑️  Deleting Cloud Storage buckets..."
gsutil -m rm -r gs://$PROJECT_ID-web || echo "Web bucket already deleted or not found"
gsutil -m rm -r gs://$PROJECT_ID-function-source || echo "Function source bucket already deleted or not found"

# Delete any remaining objects and buckets
gsutil ls -p $PROJECT_ID | while read bucket; do
    echo "Deleting bucket: $bucket"
    gsutil -m rm -r "$bucket" || echo "Failed to delete $bucket"
done

# 3. Delete BigQuery resources
echo "📊 Deleting BigQuery resources..."
bq rm -r -f $PROJECT_ID:analytics || echo "BigQuery dataset already deleted or not found"

# 4. Delete Cloud Build triggers and artifacts (if any)
echo "🏗️  Cleaning up Cloud Build resources..."
gcloud builds triggers list --format="value(id)" | while read trigger_id; do
    if [ ! -z "$trigger_id" ]; then
        echo "Deleting build trigger: $trigger_id"
        gcloud builds triggers delete $trigger_id --quiet || echo "Failed to delete trigger $trigger_id"
    fi
done

# 5. Delete Artifact Registry repositories (if any)
echo "📦 Cleaning up Artifact Registry..."
gcloud artifacts repositories list --location=$REGION --format="value(name)" | while read repo; do
    if [ ! -z "$repo" ]; then
        echo "Deleting artifact repository: $repo"
        gcloud artifacts repositories delete $(basename $repo) --location=$REGION --quiet || echo "Failed to delete repository $repo"
    fi
done

# 6. List remaining resources
echo "📋 Checking for remaining resources..."
echo "Cloud Functions:"
gcloud functions list --regions=$REGION || echo "No functions found"

echo "Cloud Storage buckets:"
gsutil ls -p $PROJECT_ID || echo "No buckets found"

echo "BigQuery datasets:"
bq ls || echo "No datasets found"

echo "✅ Cleanup completed!"
echo "Note: The project itself is still active. To delete the entire project, run:"
echo "gcloud projects delete $PROJECT_ID"

echo ""
echo "🎯 To recreate this infrastructure later, use the Terraform configuration:"
echo "cd terraform && terraform apply"