/**
 * SYMBIOSE AI Interceptor - Tests
 */

const { SymbioseInterceptor, AI_PROVIDERS } = require('../src/index');

describe('SymbioseInterceptor', () => {
  let interceptor;

  beforeEach(() => {
    interceptor = new SymbioseInterceptor();
  });

  describe('Provider Detection', () => {
    test('should detect OpenAI', () => {
      expect(interceptor.detectProvider('https://api.openai.com/v1/chat')).toBe('openai');
    });

    test('should detect Anthropic', () => {
      expect(interceptor.detectProvider('https://api.anthropic.com/v1/messages')).toBe('anthropic');
    });

    test('should detect Google', () => {
      expect(interceptor.detectProvider('https://generativelanguage.googleapis.com/v1')).toBe('google');
    });

    test('should detect Cohere', () => {
      expect(interceptor.detectProvider('https://api.cohere.ai/generate')).toBe('cohere');
    });

    test('should return unknown for unrecognized URLs', () => {
      expect(interceptor.detectProvider('https://example.com/api')).toBe('unknown');
    });
  });

  describe('Intercept Recording', () => {
    test('should record intercept with all fields', () => {
      const data = {
        provider: 'openai',
        model: 'gpt-4',
        endpoint: '/v1/chat/completions',
        latency: 1500,
        tokens: { input: 100, output: 200 },
        status: 200
      };

      const result = interceptor.recordIntercept(data);

      expect(result.provider).toBe('openai');
      expect(result.model).toBe('gpt-4');
      expect(result.latency).toBe(1500);
      expect(result.id).toBeDefined();
      expect(result.timestamp).toBeDefined();
    });

    test('should update stats after recording', () => {
      interceptor.recordIntercept({
        provider: 'openai',
        model: 'gpt-4',
        latency: 1000,
        status: 200
      });

      const stats = interceptor.getStats();
      expect(stats.total).toBe(1);
      expect(stats.byProvider.openai).toBe(1);
    });

    test('should emit intercept event', (done) => {
      interceptor.on('intercept', (data) => {
        expect(data.provider).toBe('anthropic');
        done();
      });

      interceptor.recordIntercept({
        provider: 'anthropic',
        model: 'claude-3',
        latency: 800,
        status: 200
      });
    });
  });

  describe('Cost Estimation', () => {
    test('should estimate cost for GPT-4', () => {
      const cost = interceptor.estimateCost({
        provider: 'openai',
        model: 'gpt-4',
        tokens: { input: 500, output: 500 }
      });

      expect(cost).toBe(0.03); // 1000 tokens * 0.03/1000
    });

    test('should estimate cost for Claude', () => {
      const cost = interceptor.estimateCost({
        provider: 'anthropic',
        model: 'claude-3-opus',
        tokens: { input: 1000, output: 1000 }
      });

      expect(cost).toBe(0.03); // 2000 tokens * 0.015/1000
    });

    test('should handle unknown models with default rate', () => {
      const cost = interceptor.estimateCost({
        provider: 'unknown',
        model: 'unknown',
        tokens: { input: 1000, output: 0 }
      });

      expect(cost).toBe(0.001); // 1000 tokens * 0.001/1000
    });
  });

  describe('Export', () => {
    beforeEach(() => {
      interceptor.recordIntercept({
        provider: 'openai',
        model: 'gpt-4',
        endpoint: '/chat',
        latency: 1000,
        status: 200
      });
    });

    test('should export as JSON', () => {
      const json = interceptor.export('json');
      const parsed = JSON.parse(json);
      expect(Array.isArray(parsed)).toBe(true);
      expect(parsed.length).toBe(1);
    });

    test('should export as CSV', () => {
      const csv = interceptor.export('csv');
      expect(csv).toContain('id,timestamp,provider,model');
      expect(csv).toContain('openai');
    });
  });

  describe('Statistics', () => {
    test('should calculate average latency correctly', () => {
      interceptor.recordIntercept({ provider: 'openai', latency: 1000, status: 200 });
      interceptor.recordIntercept({ provider: 'openai', latency: 2000, status: 200 });
      interceptor.recordIntercept({ provider: 'openai', latency: 3000, status: 200 });

      const stats = interceptor.getStats();
      expect(stats.avgLatency).toBe(2000);
    });

    test('should count by provider', () => {
      interceptor.recordIntercept({ provider: 'openai', latency: 1000, status: 200 });
      interceptor.recordIntercept({ provider: 'openai', latency: 1000, status: 200 });
      interceptor.recordIntercept({ provider: 'anthropic', latency: 1000, status: 200 });

      const stats = interceptor.getStats();
      expect(stats.byProvider.openai).toBe(2);
      expect(stats.byProvider.anthropic).toBe(1);
    });
  });
});

describe('AI_PROVIDERS', () => {
  test('should have all major providers', () => {
    expect(AI_PROVIDERS).toHaveProperty('openai');
    expect(AI_PROVIDERS).toHaveProperty('anthropic');
    expect(AI_PROVIDERS).toHaveProperty('google');
    expect(AI_PROVIDERS).toHaveProperty('cohere');
    expect(AI_PROVIDERS).toHaveProperty('huggingface');
  });
});
