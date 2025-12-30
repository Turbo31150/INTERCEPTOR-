/**
 * SYMBIOSE AI Interceptor
 * Main entry point
 */

const http = require('http');
const https = require('https');
const httpProxy = require('http-proxy');
const express = require('express');
const { WebSocketServer } = require('ws');
const yaml = require('js-yaml');
const fs = require('fs');
const path = require('path');
const winston = require('winston');
const EventEmitter = require('events');

// Logger setup
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    }),
    new winston.transports.File({ filename: 'logs/symbiose.log' })
  ]
});

// AI Provider patterns
const AI_PROVIDERS = {
  openai: /api\.openai\.com|chat\.openai\.com/,
  anthropic: /api\.anthropic\.com/,
  google: /generativelanguage\.googleapis\.com/,
  cohere: /api\.cohere\.ai/,
  huggingface: /api-inference\.huggingface\.co/
};

class SymbioseInterceptor extends EventEmitter {
  constructor(config = {}) {
    super();
    this.config = config;
    this.intercepts = [];
    this.stats = {
      total: 0,
      byProvider: {},
      errors: 0,
      avgLatency: 0
    };
  }

  /**
   * Detect AI provider from URL
   */
  detectProvider(url) {
    for (const [provider, pattern] of Object.entries(AI_PROVIDERS)) {
      if (pattern.test(url)) {
        return provider;
      }
    }
    return 'unknown';
  }

  /**
   * Record an interception
   */
  recordIntercept(data) {
    const intercept = {
      id: Date.now(),
      timestamp: new Date().toISOString(),
      provider: data.provider,
      model: data.model || 'unknown',
      endpoint: data.endpoint,
      latency: data.latency,
      tokens: data.tokens || { input: 0, output: 0 },
      status: data.status,
      cost: this.estimateCost(data)
    };

    this.intercepts.push(intercept);
    this.updateStats(intercept);
    this.emit('intercept', intercept);

    logger.info(`[${intercept.provider}] ${intercept.model} - ${intercept.latency}ms`);

    return intercept;
  }

  /**
   * Estimate cost based on provider and tokens
   */
  estimateCost(data) {
    const rates = {
      openai: { 'gpt-4': 0.03, 'gpt-3.5-turbo': 0.002 },
      anthropic: { 'claude-3-opus': 0.015, 'claude-3-sonnet': 0.003 }
    };

    const providerRates = rates[data.provider] || {};
    const rate = providerRates[data.model] || 0.001;
    const totalTokens = (data.tokens?.input || 0) + (data.tokens?.output || 0);

    return (totalTokens / 1000) * rate;
  }

  /**
   * Update statistics
   */
  updateStats(intercept) {
    this.stats.total++;
    this.stats.byProvider[intercept.provider] =
      (this.stats.byProvider[intercept.provider] || 0) + 1;

    // Rolling average latency
    this.stats.avgLatency =
      (this.stats.avgLatency * (this.stats.total - 1) + intercept.latency) / this.stats.total;
  }

  /**
   * Get current stats
   */
  getStats() {
    return {
      ...this.stats,
      recentIntercepts: this.intercepts.slice(-100)
    };
  }

  /**
   * Export intercepts
   */
  export(format = 'json') {
    switch (format) {
      case 'json':
        return JSON.stringify(this.intercepts, null, 2);
      case 'csv':
        const headers = 'id,timestamp,provider,model,latency,status,cost\n';
        const rows = this.intercepts.map(i =>
          `${i.id},${i.timestamp},${i.provider},${i.model},${i.latency},${i.status},${i.cost}`
        ).join('\n');
        return headers + rows;
      default:
        return this.intercepts;
    }
  }
}

// Express dashboard app
function createDashboard(interceptor, port = 3000) {
  const app = express();

  app.use(express.json());
  app.use(express.static(path.join(__dirname, 'dashboard/public')));

  // API endpoints
  app.get('/api/intercepts', (req, res) => {
    res.json(interceptor.intercepts.slice(-100));
  });

  app.get('/api/stats', (req, res) => {
    res.json(interceptor.getStats());
  });

  app.get('/api/providers', (req, res) => {
    res.json(Object.keys(AI_PROVIDERS));
  });

  app.post('/api/export', (req, res) => {
    const format = req.body.format || 'json';
    res.send(interceptor.export(format));
  });

  return app;
}

// Main startup
async function start() {
  // Load config
  let config = {};
  const configPath = path.join(__dirname, '../config.yaml');

  if (fs.existsSync(configPath)) {
    config = yaml.load(fs.readFileSync(configPath, 'utf8'));
  }

  const interceptor = new SymbioseInterceptor(config);

  // Dashboard
  const dashboardPort = config.dashboard?.port || 3000;
  const dashboard = createDashboard(interceptor, dashboardPort);

  dashboard.listen(dashboardPort, () => {
    logger.info(`Dashboard running on http://localhost:${dashboardPort}`);
  });

  // WebSocket for real-time updates
  const wss = new WebSocketServer({ port: 3001 });

  wss.on('connection', (ws) => {
    logger.info('WebSocket client connected');

    interceptor.on('intercept', (data) => {
      ws.send(JSON.stringify(data));
    });
  });

  logger.info('SYMBIOSE AI Interceptor v3.0 started');
  logger.info(`Monitoring: ${Object.keys(AI_PROVIDERS).join(', ')}`);

  return interceptor;
}

// Export for programmatic use
module.exports = { SymbioseInterceptor, createDashboard, start, AI_PROVIDERS };

// Run if called directly
if (require.main === module) {
  start().catch(console.error);
}
