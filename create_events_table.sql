CREATE TABLE `your-analytics-project.analytics.events` (
  timestamp TIMESTAMP,
  event_type STRING,
  user_id STRING,
  session_id STRING,
  url STRING,
  properties JSON
)
PARTITION BY DATE(timestamp)
CLUSTER BY event_type;