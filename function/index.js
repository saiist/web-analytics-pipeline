const { BigQuery } = require('@google-cloud/bigquery');
const { PubSub } = require('@google-cloud/pubsub');

const bigquery = new BigQuery();
const pubsub = new PubSub();

exports.trackEvent = async (req, res) => {
  // Set CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const eventData = {
      timestamp: new Date().toISOString(),
      event_type: req.body.event_type,
      user_id: req.body.user_id,
      session_id: req.body.session_id,
      url: req.body.url,
      properties: JSON.stringify(req.body.properties || {})
    };

    const datasetId = 'analytics';
    const tableId = 'events';
    
    await bigquery
      .dataset(datasetId)
      .table(tableId)
      .insert([eventData]);

    res.status(200).json({ success: true, message: 'Event tracked successfully' });
  } catch (error) {
    console.error('Error tracking event:', error);
    res.status(500).json({ error: 'Failed to track event' });
  }
};