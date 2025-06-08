<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Webイベント分析デモ</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 30px;
            text-align: center;
            margin-bottom: 30px;
            color: white;
        }
        
        h1 {
            margin: 0 0 10px 0;
            font-size: 2.5em;
        }
        
        .subtitle {
            opacity: 0.8;
            font-size: 1.1em;
        }
        
        .demo-section {
            background: rgba(255, 255, 255, 0.95);
            border-radius: 15px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
        }
        
        .section-title {
            color: #333;
            margin-bottom: 20px;
            font-size: 1.5em;
            border-bottom: 3px solid #667eea;
            padding-bottom: 10px;
        }
        
        .demo-buttons {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }
        
        .demo-btn {
            padding: 15px 25px;
            border: none;
            border-radius: 10px;
            font-size: 16px;
            cursor: pointer;
            transition: all 0.3s ease;
            color: white;
            font-weight: bold;
        }
        
        .btn-page-view { background: linear-gradient(45deg, #4CAF50, #45a049); }
        .btn-click { background: linear-gradient(45deg, #2196F3, #1976D2); }
        .btn-purchase { background: linear-gradient(45deg, #FF9800, #F57C00); }
        .btn-signup { background: linear-gradient(45deg, #9C27B0, #7B1FA2); }
        
        .demo-btn:hover {
            transform: translateY(-3px);
            box-shadow: 0 10px 20px rgba(0, 0, 0, 0.2);
        }
        
        .analytics-display {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            margin-top: 20px;
        }
        
        .metric-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .metric-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            box-shadow: 0 3px 10px rgba(0, 0, 0, 0.1);
        }
        
        .metric-number {
            font-size: 2em;
            font-weight: bold;
            color: #667eea;
            margin-bottom: 5px;
        }
        
        .metric-label {
            color: #666;
            font-size: 0.9em;
        }
        
        .event-log {
            background: #2d3748;
            color: #e2e8f0;
            padding: 20px;
            border-radius: 10px;
            font-family: 'Courier New', monospace;
            font-size: 14px;
            max-height: 300px;
            overflow-y: auto;
        }
        
        .log-entry {
            margin-bottom: 8px;
            padding: 8px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 5px;
            animation: fadeIn 0.5s ease-in;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .timestamp {
            color: #90cdf4;
        }
        
        .event-type {
            color: #68d391;
            font-weight: bold;
        }
        
        .gcp-code {
            background: #1a202c;
            color: #e2e8f0;
            padding: 20px;
            border-radius: 10px;
            font-family: 'Courier New', monospace;
            font-size: 13px;
            overflow-x: auto;
            margin-top: 15px;
        }
        
        .code-comment {
            color: #90cdf4;
        }
        
        .code-keyword {
            color: #68d391;
        }
        
        .code-string {
            color: #fbb6ce;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Webイベント分析デモ</h1>
            <p class="subtitle">Google Cloudでリアルタイム分析を体験</p>
        </div>
        
        <div class="demo-section">
            <h2 class="section-title">📊 イベント発生デモ</h2>
            <p>以下のボタンをクリックして、様々なWebイベントを発生させてください：</p>
            
            <div class="demo-buttons">
                <button class="demo-btn btn-page-view" onclick="trackEvent('page_view')">
                    👁️ ページビュー
                </button>
                <button class="demo-btn btn-click" onclick="trackEvent('button_click')">
                    🖱️ ボタンクリック
                </button>
                <button class="demo-btn btn-purchase" onclick="trackEvent('purchase')">
                    🛒 購入完了
                </button>
                <button class="demo-btn btn-signup" onclick="trackEvent('signup')">
                    ✍️ 新規登録
                </button>
            </div>
            
            <div class="analytics-display">
                <h3>📈 リアルタイム分析結果</h3>
                
                <div class="metric-cards">
                    <div class="metric-card">
                        <div class="metric-number" id="total-events">0</div>
                        <div class="metric-label">総イベント数</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-number" id="page-views">0</div>
                        <div class="metric-label">ページビュー</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-number" id="conversions">0</div>
                        <div class="metric-label">コンバージョン</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-number" id="avg-time">0.0s</div>
                        <div class="metric-label">平均セッション時間</div>
                    </div>
                </div>
                
                <h4>🔍 イベントログ（最新10件）</h4>
                <div class="event-log" id="event-log">
                    <div class="log-entry">
                        <span class="timestamp">[システム起動]</span> 
                        <span class="event-type">READY</span> - 分析システムが準備完了しました
                    </div>
                </div>
            </div>
        </div>
        
        <div class="demo-section">
            <h2 class="section-title">⚙️ Google Cloud実装例</h2>
            <p>このデモを実際のGoogle Cloudで実装する場合のコード例：</p>
            
            <h4>1. フロントエンド → Cloud Functions</h4>
            <div class="gcp-code">
<span class="code-comment">// JavaScript (フロントエンド)</span>
<span class="code-keyword">async function</span> trackEvent(eventType) {
  <span class="code-keyword">const</span> data = {
    event_type: eventType,
    timestamp: <span class="code-keyword">new</span> Date().toISOString(),
    user_id: <span class="code-string">'user_' + Math.random().toString(36).substr(2, 9)</span>,
    session_id: sessionStorage.getItem(<span class="code-string">'session_id'</span>),
    url: window.location.href,
    user_agent: navigator.userAgent
  };
  
  <span class="code-comment">// Cloud Functions経由でBigQueryに送信</span>
  <span class="code-keyword">await</span> fetch(<span class="code-string">'${function_url}'</span>, {
    method: <span class="code-string">'POST'</span>,
    headers: { <span class="code-string">'Content-Type'</span>: <span class="code-string">'application/json'</span> },
    body: JSON.stringify(data)
  });
}
            </div>
            
            <h4>2. Cloud Functions → BigQuery</h4>
            <div class="gcp-code">
<span class="code-comment">// Node.js (Cloud Functions)</span>
<span class="code-keyword">const</span> {BigQuery} = require(<span class="code-string">'@google-cloud/bigquery'</span>);

exports.trackEvent = <span class="code-keyword">async</span> (req, res) => {
  <span class="code-keyword">const</span> eventData = {
    timestamp: req.body.timestamp,
    event_type: req.body.event_type,
    user_id: req.body.user_id,
    session_id: req.body.session_id,
    properties: JSON.stringify(req.body.properties)
  };
  
  <span class="code-keyword">const</span> bigquery = <span class="code-keyword">new</span> BigQuery();
  <span class="code-comment">// BigQueryにリアルタイム挿入</span>
  <span class="code-keyword">await</span> bigquery
    .dataset(<span class="code-string">'analytics'</span>)
    .table(<span class="code-string">'events'</span>)
    .insert([eventData]);
};
            </div>
            
            <h4>3. BigQuery分析クエリ</h4>
            <div class="gcp-code">
<span class="code-comment">-- リアルタイムダッシュボード用SQL</span>
<span class="code-keyword">SELECT</span>
  FORMAT_TIMESTAMP(<span class="code-string">'%H:%M'</span>, timestamp) <span class="code-keyword">as</span> time_bucket,
  event_type,
  COUNT(*) <span class="code-keyword">as</span> event_count,
  COUNT(DISTINCT user_id) <span class="code-keyword">as</span> unique_users
<span class="code-keyword">FROM</span> `${project_id}.analytics.events`
<span class="code-keyword">WHERE</span> timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), <span class="code-keyword">INTERVAL</span> 1 <span class="code-keyword">HOUR</span>)
<span class="code-keyword">GROUP BY</span> time_bucket, event_type
<span class="code-keyword">ORDER BY</span> time_bucket <span class="code-keyword">DESC</span>
            </div>
        </div>
    </div>

    <script>
        // 分析データ保存
        let analytics = {
            totalEvents: 0,
            pageViews: 0,
            conversions: 0,
            sessionStart: Date.now(),
            events: []
        };
        
        // セッションID生成
        if (!sessionStorage.getItem('session_id')) {
            sessionStorage.setItem('session_id', 'session_' + Math.random().toString(36).substr(2, 9));
        }
        
        // Cloud Function URL (Terraform automatically replaced)
        const CLOUD_FUNCTION_URL = '${function_url}';
        
        function trackEvent(eventType) {
            const timestamp = new Date();
            const eventData = {
                event_type: eventType,
                timestamp: timestamp.toISOString(),
                user_id: 'user_' + Math.random().toString(36).substr(2, 5),
                session_id: sessionStorage.getItem('session_id'),
                url: window.location.href,
                properties: {
                    browser: navigator.userAgent,
                    screen_resolution: screen.width + 'x' + screen.height,
                    page_title: document.title
                }
            };
            
            // 分析データ更新
            analytics.totalEvents++;
            analytics.events.push(eventData);
            
            if (eventType === 'page_view') {
                analytics.pageViews++;
            }
            if (eventType === 'purchase' || eventType === 'signup') {
                analytics.conversions++;
            }
            
            // UI更新
            updateMetrics();
            addLogEntry(eventData);
            
            // Cloud Functionsに送信
            console.log('Sending to:', CLOUD_FUNCTION_URL);
            console.log('Event data:', eventData);
            fetch(CLOUD_FUNCTION_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(eventData)
            })
            .then(response => {
                console.log('Response status:', response.status);
                return response.json();
            })
            .then(data => {
                console.log('Event sent to BigQuery:', data);
                updateLogEntryStatus(eventData.timestamp, '✓ BigQueryに保存済み');
            })
            .catch(error => {
                console.error('Error sending event:', error);
                updateLogEntryStatus(eventData.timestamp, '✗ 送信エラー');
            });
        }
        
        function updateMetrics() {
            document.getElementById('total-events').textContent = analytics.totalEvents;
            document.getElementById('page-views').textContent = analytics.pageViews;
            document.getElementById('conversions').textContent = analytics.conversions;
            
            const sessionTime = (Date.now() - analytics.sessionStart) / 1000;
            document.getElementById('avg-time').textContent = sessionTime.toFixed(1) + 's';
        }
        
        function addLogEntry(eventData) {
            const logContainer = document.getElementById('event-log');
            const entry = document.createElement('div');
            entry.className = 'log-entry';
            entry.id = 'entry-' + eventData.timestamp;
            
            const time = new Date(eventData.timestamp).toLocaleTimeString();
            entry.innerHTML = 
                '<span class="timestamp">[' + time + ']</span>' +
                '<span class="event-type">' + eventData.event_type.toUpperCase() + '</span>' +
                ' - User: ' + eventData.user_id + ' | Session: ' + eventData.session_id.substr(-8) +
                '<span class="status" style="color: #fbb6ce; margin-left: 10px;">⏳ 送信中...</span>';
            
            logContainer.insertBefore(entry, logContainer.children[1]);
            
            // 最新10件のみ表示
            while (logContainer.children.length > 11) {
                logContainer.removeChild(logContainer.lastChild);
            }
        }
        
        function updateLogEntryStatus(timestamp, status) {
            const entry = document.getElementById('entry-' + timestamp);
            if (entry) {
                const statusSpan = entry.querySelector('.status');
                if (statusSpan) {
                    statusSpan.textContent = status;
                    statusSpan.style.color = status.includes('✓') ? '#68d391' : '#f56565';
                }
            }
        }
        
        // 初回ページビューを自動トラッキング
        setTimeout(() => trackEvent('page_view'), 1000);
        
        // 定期的にランダムイベント生成（デモ用）
        setInterval(() => {
            const events = ['page_view', 'button_click'];
            const randomEvent = events[Math.floor(Math.random() * events.length)];
            if (Math.random() < 0.3) { // 30%の確率
                trackEvent(randomEvent);
            }
        }, 5000);
    </script>
</body>
</html>