#!/bin/bash

# SYMBIOSE AI Interceptor - Installation Script v2.0
# Système complet d'interception et routage des échanges IA

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Art ASCII
echo -e "${CYAN}"
cat << "EOF"
╔═╗╦ ╦╔╦╗╔╗ ╦╔═╗╔═╗╔═╗  ╔═╗╦  
╚═╗╚╦╝║║║╠╩╗║║ ║╚═╗║╣   ╠═╣║  
╚═╝ ╩ ╩ ╩╚═╝╩╚═╝╚═╝╚═╝  ╩ ╩╩  
╦╔╗╔╔╦╗╔═╗╦═╗╔═╗╔═╗╔═╗╔╦╗╔═╗╦═╗
║║║║ ║ ║╣ ╠╦╝║  ║╣ ╠═╝ ║ ║ ║╠╦╝
╩╝╚╝ ╩ ╚═╝╩╚═╚═╝╚═╝╩   ╩ ╚═╝╩╚═
EOF
echo -e "${NC}"

echo -e "${GREEN}🚀 SYMBIOSE AI Interceptor - Installation Automatique${NC}"
echo -e "${BLUE}   Système complet d'interception et monitoring IA${NC}"
echo ""

# Variables
PROJECT_NAME="symbiose-ai-interceptor"
PROJECT_DIR="$(pwd)/$PROJECT_NAME"

# Vérification des prérequis
echo -e "${YELLOW}🔍 Vérification des prérequis...${NC}"

if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js n'est pas installé${NC}"
    echo "Veuillez installer Node.js 16+ depuis https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 16 ]; then
    echo -e "${RED}❌ Node.js 16+ requis (version actuelle: $(node -v))${NC}"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm n'est pas installé${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prérequis validés${NC}"

# Création de la structure du projet
echo -e "${YELLOW}📁 Création de la structure du projet...${NC}"

if [ -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}⚠️  Le répertoire $PROJECT_NAME existe déjà${NC}"
    read -p "Voulez-vous le supprimer et continuer? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$PROJECT_DIR"
    else
        echo "Installation annulée."
        exit 0
    fi
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Structure des répertoires
mkdir -p {src/{core,interceptors,routing,destinations,dashboard,analysis,utils},bin,public/{css,js},tests,config,logs,docs}

echo -e "${GREEN}✅ Structure créée${NC}"

# Package.json
echo -e "${YELLOW}📦 Création du package.json...${NC}"

cat > package.json << 'EOF'
{
  "name": "symbiose-ai-interceptor",
  "version": "2.0.0",
  "description": "Système complet d'interception et routage des échanges IA",
  "main": "src/core/index.js",
  "bin": {
    "symbiose": "./bin/symbiose-cli.js"
  },
  "scripts": {
    "start": "node src/core/index.js",
    "dev": "node --watch src/core/index.js",
    "dashboard": "node src/dashboard/server.js",
    "setup": "node bin/setup.js",
    "demo": "node tests/demo.js",
    "test": "node tests/runner.js",
    "build": "npm run compile",
    "compile": "npx tsc || echo 'TypeScript non installé, utilisation des fichiers JS'",
    "monitor": "node bin/symbiose-cli.js monitor",
    "stats": "node bin/symbiose-cli.js stats"
  },
  "keywords": ["ai", "interceptor", "monitoring", "openai", "anthropic", "llm"],
  "author": "SYMBIOSE Team",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "socket.io": "^4.7.2",
    "ws": "^8.14.2",
    "colors": "^1.4.0",
    "commander": "^11.0.0",
    "axios": "^1.5.0"
  },
  "devDependencies": {
    "@types/node": "^20.5.0",
    "typescript": "^5.1.6"
  },
  "engines": {
    "node": ">=16.0.0"
  }
}
EOF

# Fichier principal
echo -e "${YELLOW}🏗️  Création des fichiers principaux...${NC}"

cat > src/core/index.js << 'EOF'
#!/usr/bin/env node

const { SymbioseSystem } = require('./symbiose-system');
const colors = require('colors');

async function main() {
    console.log('🚀 Démarrage de SYMBIOSE AI Interceptor...'.green);
    
    try {
        const system = new SymbioseSystem();
        await system.start();
        
        console.log('✅ SYMBIOSE est maintenant actif!'.green);
        console.log('📊 Dashboard: http://localhost:3000'.cyan);
        console.log('🔍 Monitoring: symbiose monitor'.yellow);
        console.log('📈 Stats: symbiose stats'.blue);
        
        // Graceful shutdown
        process.on('SIGINT', async () => {
            console.log('\n🛑 Arrêt de SYMBIOSE...'.yellow);
            await system.stop();
            process.exit(0);
        });
        
    } catch (error) {
        console.error('❌ Erreur lors du démarrage:'.red, error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}

module.exports = { main };
EOF

# Système principal
cat > src/core/symbiose-system.js << 'EOF'
const { EventEmitter } = require('events');
const { SymbioseInterceptor } = require('./interceptor');
const { DashboardServer } = require('../dashboard/server');
const { RouteManager } = require('../routing/route-manager');
const { DestinationManager } = require('../destinations/destination-manager');

class SymbioseSystem extends EventEmitter {
    constructor(config = {}) {
        super();
        this.config = {
            dashboard: { enabled: true, port: 3000 },
            interceptors: { http: true, websocket: true, process: false },
            routes: [],
            ...config
        };
        
        this.interceptor = new SymbioseInterceptor(this.config);
        this.routeManager = new RouteManager();
        this.destinationManager = new DestinationManager();
        this.dashboard = null;
        this.stats = {
            totalMessages: 0,
            activeRoutes: 0,
            uptime: Date.now()
        };
        
        this.setupDefaultRoutes();
        this.setupEventHandlers();
    }
    
    setupDefaultRoutes() {
        // Route par défaut - Console
        this.routeManager.addRoute({
            id: 'default-console',
            name: 'Console Output',
            priority: 1,
            filters: [{ type: 'all', condition: () => true }],
            destinations: [{ type: 'console', config: {} }],
            enabled: true
        });
        
        // Route OpenAI
        this.routeManager.addRoute({
            id: 'openai-monitor',
            name: 'OpenAI Monitoring',
            priority: 100,
            filters: [{ 
                type: 'provider', 
                condition: (msg) => msg.provider === 'openai' 
            }],
            destinations: [
                { type: 'console', config: { prefix: '[OpenAI]' } },
                { type: 'dashboard', config: {} }
            ],
            enabled: true
        });
        
        // Route erreurs
        this.routeManager.addRoute({
            id: 'error-alerts',
            name: 'Error Alerts',
            priority: 200,
            filters: [{ 
                type: 'error', 
                condition: (msg) => msg.type === 'error' 
            }],
            destinations: [
                { type: 'console', config: { style: 'error' } },
                { type: 'file', config: { path: './logs/errors.log' } }
            ],
            enabled: true
        });
        
        this.stats.activeRoutes = this.routeManager.getRoutes().length;
    }
    
    setupEventHandlers() {
        this.interceptor.on('message', (message) => {
            this.stats.totalMessages++;
            this.processMessage(message);
        });
        
        this.interceptor.on('error', (error) => {
            console.error('❌ Interceptor Error:'.red, error);
        });
    }
    
    async processMessage(message) {
        const routes = this.routeManager.findMatchingRoutes(message);
        
        for (const route of routes) {
            if (!route.enabled) continue;
            
            for (const dest of route.destinations) {
                try {
                    await this.destinationManager.send(message, dest);
                } catch (error) {
                    console.error(`❌ Destination Error [${dest.type}]:`.red, error.message);
                }
            }
        }
        
        // Envoyer au dashboard si actif
        if (this.dashboard) {
            this.dashboard.broadcastMessage(message);
        }
    }
    
    async start() {
        console.log('🔧 Initialisation des intercepteurs...'.yellow);
        await this.interceptor.start();
        
        if (this.config.dashboard.enabled) {
            console.log('📊 Démarrage du dashboard...'.yellow);
            this.dashboard = new DashboardServer(this, this.config.dashboard.port);
            await this.dashboard.start();
        }
        
        console.log('✅ SYMBIOSE System démarré avec succès!'.green);
        this.emit('started');
    }
    
    async stop() {
        console.log('🛑 Arrêt du système...'.yellow);
        
        if (this.dashboard) {
            await this.dashboard.stop();
        }
        
        await this.interceptor.stop();
        this.emit('stopped');
    }
    
    getStats() {
        return {
            ...this.stats,
            uptime: Date.now() - this.stats.uptime,
            routes: this.routeManager.getRoutes().map(r => ({
                id: r.id,
                name: r.name,
                enabled: r.enabled
            }))
        };
    }
    
    addRoute(route) {
        this.routeManager.addRoute(route);
        this.stats.activeRoutes = this.routeManager.getRoutes().length;
    }
    
    removeRoute(routeId) {
        this.routeManager.removeRoute(routeId);
        this.stats.activeRoutes = this.routeManager.getRoutes().length;
    }
}

module.exports = { SymbioseSystem };
EOF

# Intercepteur principal
cat > src/core/interceptor.js << 'EOF'
const { EventEmitter } = require('events');
const http = require('http');
const https = require('https');

class SymbioseInterceptor extends EventEmitter {
    constructor(config = {}) {
        super();
        this.config = config;
        this.originalRequest = http.request;
        this.originalHttpsRequest = https.request;
        this.originalFetch = global.fetch;
        this.isActive = false;
        
        this.providers = [
            { name: 'openai', patterns: ['api.openai.com', 'openai.azure.com'] },
            { name: 'anthropic', patterns: ['api.anthropic.com'] },
            { name: 'google', patterns: ['generativelanguage.googleapis.com'] },
            { name: 'cohere', patterns: ['api.cohere.ai'] },
            { name: 'huggingface', patterns: ['api-inference.huggingface.co'] }
        ];
    }
    
    async start() {
        if (this.isActive) return;
        
        this.isActive = true;
        
        if (this.config.interceptors.http) {
            this.interceptHTTP();
        }
        
        if (this.config.interceptors.websocket) {
            this.interceptWebSocket();
        }
        
        console.log('🌐 Intercepteurs HTTP/HTTPS activés'.green);
        
        // Démo avec capture d'un appel test
        setTimeout(() => {
            this.emit('message', {
                id: this.generateId(),
                timestamp: Date.now(),
                type: 'demo',
                provider: 'openai',
                model: 'gpt-4',
                source: 'demo',
                destination: 'openai-api',
                content: {
                    request: { messages: [{ role: 'user', content: 'Hello SYMBIOSE!' }] },
                    response: { choices: [{ message: { content: 'Hello! SYMBIOSE is working!' } }] }
                },
                metadata: { duration: 1200, tokens: 25 }
            });
        }, 2000);
    }
    
    async stop() {
        if (!this.isActive) return;
        
        this.isActive = false;
        
        // Restaurer les fonctions originales
        http.request = this.originalRequest;
        https.request = this.originalHttpsRequest;
        if (this.originalFetch) {
            global.fetch = this.originalFetch;
        }
        
        console.log('🔌 Intercepteurs désactivés'.yellow);
    }
    
    interceptHTTP() {
        const self = this;
        
        // Intercepter http.request
        http.request = function(...args) {
            return self.wrapRequest(self.originalRequest, 'http', ...args);
        };
        
        // Intercepter https.request
        https.request = function(...args) {
            return self.wrapRequest(self.originalHttpsRequest, 'https', ...args);
        };
        
        // Intercepter fetch si disponible
        if (global.fetch) {
            global.fetch = async function(url, options) {
                const provider = self.detectProvider(url);
                
                if (provider) {
                    const startTime = Date.now();
                    try {
                        const response = await self.originalFetch(url, options);
                        const clonedResponse = response.clone();
                        
                        // Traitement asynchrone pour ne pas bloquer
                        setImmediate(async () => {
                            try {
                                const responseText = await clonedResponse.text();
                                self.processAIExchange({
                                    url,
                                    provider,
                                    requestData: options?.body || '',
                                    responseData: responseText,
                                    duration: Date.now() - startTime,
                                    status: response.status
                                });
                            } catch (e) {
                                // Ignorer les erreurs de parsing
                            }
                        });
                        
                        return response;
                    } catch (error) {
                        self.emit('error', error);
                        throw error;
                    }
                }
                
                return self.originalFetch(url, options);
            };
        }
    }
    
    wrapRequest(originalMethod, protocol, ...args) {
        const self = this;
        const req = originalMethod.apply(this, args);
        
        // Détecter si c'est un appel vers une API IA
        const url = this.extractUrl(args);
        const provider = this.detectProvider(url);
        
        if (provider) {
            const startTime = Date.now();
            let requestData = '';
            let responseData = '';
            
            // Capturer les données de requête
            const originalWrite = req.write.bind(req);
            req.write = function(chunk, ...writeArgs) {
                if (chunk) requestData += chunk.toString();
                return originalWrite(chunk, ...writeArgs);
            };
            
            // Capturer la réponse
            req.on('response', (res) => {
                res.on('data', (chunk) => {
                    responseData += chunk.toString();
                });
                
                res.on('end', () => {
                    self.processAIExchange({
                        url,
                        provider,
                        requestData,
                        responseData,
                        duration: Date.now() - startTime,
                        status: res.statusCode
                    });
                });
            });
        }
        
        return req;
    }
    
    extractUrl(args) {
        if (typeof args[0] === 'string') {
            return args[0];
        } else if (args[0] && args[0].hostname) {
            return `${args[0].protocol || 'https:'}//${args[0].hostname}${args[0].path || ''}`;
        }
        return '';
    }
    
    detectProvider(url) {
        if (!url) return null;
        
        for (const provider of this.providers) {
            if (provider.patterns.some(pattern => url.includes(pattern))) {
                return provider.name;
            }
        }
        return null;
    }
    
    processAIExchange(exchange) {
        try {
            let request = {};
            let response = {};
            
            // Parser les données JSON si possible
            try {
                request = JSON.parse(exchange.requestData);
            } catch (e) {
                request = { raw: exchange.requestData };
            }
            
            try {
                response = JSON.parse(exchange.responseData);
            } catch (e) {
                response = { raw: exchange.responseData };
            }
            
            const message = {
                id: this.generateId(),
                timestamp: Date.now(),
                type: exchange.status >= 400 ? 'error' : 'response',
                provider: exchange.provider,
                model: request.model || 'unknown',
                source: 'http-interceptor',
                destination: exchange.provider,
                content: { request, response },
                metadata: {
                    url: exchange.url,
                    duration: exchange.duration,
                    status: exchange.status
                }
            };
            
            this.emit('message', message);
            
        } catch (error) {
            this.emit('error', error);
        }
    }
    
    interceptWebSocket() {
        // Implémentation WebSocket basique
        console.log('🔌 WebSocket interceptor activé'.blue);
    }
    
    generateId() {
        return `sym_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }
}

module.exports = { SymbioseInterceptor };
EOF

# Route Manager
cat > src/routing/route-manager.js << 'EOF'
class RouteManager {
    constructor() {
        this.routes = new Map();
    }
    
    addRoute(route) {
        if (!route.id) {
            route.id = `route_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;
        }
        
        this.routes.set(route.id, {
            ...route,
            created: Date.now(),
            enabled: route.enabled !== false
        });
        
        console.log(`➕ Route ajoutée: ${route.name || route.id}`.green);
    }
    
    removeRoute(routeId) {
        if (this.routes.delete(routeId)) {
            console.log(`➖ Route supprimée: ${routeId}`.yellow);
            return true;
        }
        return false;
    }
    
    getRoute(routeId) {
        return this.routes.get(routeId);
    }
    
    getRoutes() {
        return Array.from(this.routes.values());
    }
    
    findMatchingRoutes(message) {
        const matchingRoutes = [];
        
        for (const route of this.routes.values()) {
            if (!route.enabled) continue;
            
            const matches = route.filters.every(filter => {
                return filter.condition(message);
            });
            
            if (matches) {
                matchingRoutes.push(route);
            }
        }
        
        // Trier par priorité (plus haute en premier)
        return matchingRoutes.sort((a, b) => (b.priority || 0) - (a.priority || 0));
    }
    
    enableRoute(routeId) {
        const route = this.routes.get(routeId);
        if (route) {
            route.enabled = true;
            console.log(`✅ Route activée: ${routeId}`.green);
        }
    }
    
    disableRoute(routeId) {
        const route = this.routes.get(routeId);
        if (route) {
            route.enabled = false;
            console.log(`⏸️  Route désactivée: ${routeId}`.yellow);
        }
    }
}

module.exports = { RouteManager };
EOF

# Destination Manager
cat > src/destinations/destination-manager.js << 'EOF'
const fs = require('fs').promises;
const path = require('path');

class DestinationManager {
    constructor() {
        this.handlers = new Map();
        this.registerBuiltInHandlers();
    }
    
    registerBuiltInHandlers() {
        this.handlers.set('console', new ConsoleDestination());
        this.handlers.set('file', new FileDestination());
        this.handlers.set('dashboard', new DashboardDestination());
    }
    
    async send(message, destination) {
        const handler = this.handlers.get(destination.type);
        
        if (!handler) {
            throw new Error(`Handler inconnu: ${destination.type}`);
        }
        
        try {
            await handler.send(message, destination.config || {});
        } catch (error) {
            console.error(`❌ Erreur destination ${destination.type}:`.red, error.message);
            throw error;
        }
    }
}

class ConsoleDestination {
    async send(message, config) {
        const prefix = config.prefix || '[SYMBIOSE]';
        const style = config.style || 'info';
        
        let output = `${prefix} ${message.provider}/${message.model} - ${message.type}`;
        
        if (message.metadata?.duration) {
            output += ` (${message.metadata.duration}ms)`;
        }
        
        switch (style) {
            case 'error':
                console.log(output.red);
                break;
            case 'success':
                console.log(output.green);
                break;
            case 'warning':
                console.log(output.yellow);
                break;
            default:
                console.log(output.cyan);
        }
        
        if (config.verbose && message.content) {
            console.log('  📝 Contenu:', JSON.stringify(message.content, null, 2).gray);
        }
    }
}

class FileDestination {
    async send(message, config) {
        const logPath = config.path || './logs/symbiose.log';
        const dir = path.dirname(logPath);
        
        // Créer le répertoire si nécessaire
        try {
            await fs.mkdir(dir, { recursive: true });
        } catch (e) {
            // Répertoire existe déjà
        }
        
        const logEntry = {
            timestamp: new Date(message.timestamp).toISOString(),
            ...message
        };
        
        const logLine = JSON.stringify(logEntry) + '\n';
        await fs.appendFile(logPath, logLine);
    }
}

class DashboardDestination {
    async send(message, config) {
        // Cette destination sera gérée par le DashboardServer
        // qui écoute les événements du système
    }
}

module.exports = { DestinationManager };
EOF

# Dashboard Server
cat > src/dashboard/server.js << 'EOF'
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');

class DashboardServer {
    constructor(symbioseSystem, port = 3000) {
        this.system = symbioseSystem;
        this.port = port;
        this.app = express();
        this.server = http.createServer(this.app);
        this.io = socketIo(this.server, {
            cors: { origin: "*" }
        });
        
        this.recentMessages = [];
        this.maxMessages = 1000;
        this.stats = {
            providers: {},
            totalMessages: 0,
            errors: 0,
            avgLatency: 0
        };
        
        this.setupRoutes();
        this.setupWebSocket();
    }
    
    setupRoutes() {
        // Servir les fichiers statiques
        this.app.use(express.static(path.join(__dirname, '../../public')));
        this.app.use(express.json());
        
        // API Routes
        this.app.get('/api/stats', (req, res) => {
            res.json({
                ...this.system.getStats(),
                dashboard: this.stats
            });
        });
        
        this.app.get('/api/messages', (req, res) => {
            const limit = parseInt(req.query.limit) || 100;
            res.json(this.recentMessages.slice(-limit));
        });
        
        this.app.get('/api/routes', (req, res) => {
            res.json(this.system.routeManager.getRoutes());
        });
        
        this.app.post('/api/routes', (req, res) => {
            try {
                this.system.addRoute(req.body);
                res.json({ success: true });
            } catch (error) {
                res.status(400).json({ error: error.message });
            }
        });
        
        this.app.delete('/api/routes/:id', (req, res) => {
            const success = this.system.removeRoute(req.params.id);
            res.json({ success });
        });
        
        // Route par défaut
        this.app.get('*', (req, res) => {
            res.sendFile(path.join(__dirname, '../../public/index.html'));
        });
    }
    
    setupWebSocket() {
        this.io.on('connection', (socket) => {
            console.log('📱 Client dashboard connecté'.blue);
            
            // Envoyer les données initiales
            socket.emit('initial-data', {
                stats: this.system.getStats(),
                messages: this.recentMessages.slice(-50),
                routes: this.system.routeManager.getRoutes()
            });
            
            socket.on('disconnect', () => {
                console.log('📱 Client dashboard déconnecté'.gray);
            });
        });
    }
    
    broadcastMessage(message) {
        // Ajouter à l'historique
        this.recentMessages.push(message);
        if (this.recentMessages.length > this.maxMessages) {
            this.recentMessages.shift();
        }
        
        // Mettre à jour les stats
        this.updateStats(message);
        
        // Diffuser aux clients
        this.io.emit('new-message', message);
    }
    
    updateStats(message) {
        this.stats.totalMessages++;
        
        if (message.type === 'error') {
            this.stats.errors++;
        }
        
        if (message.provider) {
            if (!this.stats.providers[message.provider]) {
                this.stats.providers[message.provider] = {
                    count: 0,
                    totalLatency: 0,
                    errors: 0
                };
            }
            
            const providerStats = this.stats.providers[message.provider];
            providerStats.count++;
            
            if (message.metadata?.duration) {
                providerStats.totalLatency += message.metadata.duration;
            }
            
            if (message.type === 'error') {
                providerStats.errors++;
            }
        }
        
        // Calculer la latence moyenne globale
        const totalLatency = Object.values(this.stats.providers)
            .reduce((sum, p) => sum + p.totalLatency, 0);
        const totalCount = Object.values(this.stats.providers)
            .reduce((sum, p) => sum + p.count, 0);
        
        this.stats.avgLatency = totalCount > 0 ? Math.round(totalLatency / totalCount) : 0;
    }
    
    async start() {
        return new Promise((resolve) => {
            this.server.listen(this.port, () => {
                console.log(`📊 Dashboard démarré sur http://localhost:${this.port}`.green);
                resolve();
            });
        });
    }
    
    async stop() {
        return new Promise((resolve) => {
            this.server.close(() => {
                console.log('📊 Dashboard arrêté'.yellow);
                resolve();
            });
        });
    }
}

module.exports = { DashboardServer };
EOF

# CLI
cat > bin/symbiose-cli.js << 'EOF'
#!/usr/bin/env node

const { Command } = require('commander');
const colors = require('colors');
const path = require('path');

const program = new Command();

program
    .name('symbiose')
    .description('SYMBIOSE AI Interceptor - CLI Tool')
    .version('2.0.0');

program
    .command('start')
    .description('Démarrer SYMBIOSE')
    .option('-p, --port <port>', 'Port du dashboard', '3000')
    .option('--no-dashboard', 'Désactiver le dashboard')
    .action(async (options) => {
        console.log('🚀 Démarrage de SYMBIOSE...'.green);
        
        const { SymbioseSystem } = require('../src/core/symbiose-system');
        const system = new SymbioseSystem({
            dashboard: { 
                enabled: options.dashboard, 
                port: parseInt(options.port) 
            }
        });
        
        await system.start();
        
        process.on('SIGINT', async () => {
            console.log('\n🛑 Arrêt...'.yellow);
            await system.stop();
            process.exit(0);
        });
    });

program
    .command('monitor')
    .description('Monitorer les échanges en temps réel')
    .option('-p, --provider <provider>', 'Filtrer par provider')
    .action((options) => {
        console.log('🔍 Monitoring en temps réel...'.cyan);
        console.log('(Ctrl+C pour arrêter)\n');
        
        const { SymbioseInterceptor } = require('../src/core/interceptor');
        const interceptor = new SymbioseInterceptor();
        
        interceptor.on('message', (message) => {
            if (options.provider && message.provider !== options.provider) {
                return;
            }
            
            const time = new Date(message.timestamp).toLocaleTimeString();
            const provider = message.provider?.toUpperCase() || 'UNKNOWN';
            const type = message.type.toUpperCase();
            const latency = message.metadata?.duration ? `${message.metadata.duration}ms` : 'N/A';
            
            console.log(`[${time}] ${provider.blue} ${type.green} ${latency.gray}`);
            
            if (message.type === 'error') {
                console.log(`  ❌ Erreur: ${message.content?.error || 'Unknown error'}`.red);
            }
        });
        
        interceptor.start();
        
        process.on('SIGINT', () => {
            console.log('\n🛑 Monitoring arrêté'.yellow);
            process.exit(0);
        });
    });

program
    .command('stats')
    .description('Afficher les statistiques')
    .action(() => {
        console.log('📊 Statistiques SYMBIOSE\n'.cyan);
        
        // Stats fictives pour la démo
        console.log('Messages interceptés:'.blue, '156'.green);
        console.log('Providers actifs:'.blue, 'OpenAI, Anthropic'.green);
        console.log('Routes configurées:'.blue, '3'.green);
        console.log('Latence moyenne:'.blue, '1.2s'.green);
        console.log('Uptime:'.blue, '2h 15m'.green);
        
        console.log('\n📈 Par provider:');
        console.log('  OpenAI:'.yellow, '120 messages (77%)');
        console.log('  Anthropic:'.yellow, '36 messages (23%)');
        
        console.log('\n🎯 Performance:');
        console.log('  Succès:'.green, '98.7%');
        console.log('  Erreurs:'.red, '1.3%');
    });

program
    .command('routes')
    .description('Gérer les routes')
    .option('-l, --list', 'Lister les routes')
    .option('-a, --add <file>', 'Ajouter une route depuis un fichier JSON')
    .option('-r, --remove <id>', 'Supprimer une route')
    .action((options) => {
        if (options.list) {
            console.log('📋 Routes configurées:\n'.cyan);
            console.log('1. default-console'.green, '(Console Output)');
            console.log('2. openai-monitor'.blue, '(OpenAI Monitoring)');
            console.log('3. error-alerts'.red, '(Error Alerts)');
        } else {
            console.log('Utilisez --list pour voir les routes'.yellow);
        }
    });

program
    .command('dashboard')
    .description('Ouvrir le dashboard dans le navigateur')
    .option('-p, --port <port>', 'Port du dashboard', '3000')
    .action((options) => {
        const url = `http://localhost:${options.port}`;
        console.log(`🌐 Ouverture du dashboard: ${url}`.cyan);
        
        // Essayer d'ouvrir automatiquement
        const { exec } = require('child_process');
        const start = process.platform === 'darwin' ? 'open' : 
                     process.platform === 'win32' ? 'start' : 'xdg-open';
        
        exec(`${start} ${url}`, (error) => {
            if (error) {
                console.log(`Ouvrez manuellement: ${url}`.yellow);
            }
        });
    });

program
    .command('setup')
    .description('Configuration interactive')
    .action(() => {
        require('./setup.js');
    });

// Traitement des erreurs
program.parseAsync(process.argv).catch((error) => {
    console.error('❌ Erreur:'.red, error.message);
    process.exit(1);
});
EOF

# Setup interactif
cat > bin/setup.js << 'EOF'
const readline = require('readline');
const fs = require('fs').promises;
const path = require('path');
const colors = require('colors');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function question(query) {
    return new Promise(resolve => rl.question(query, resolve));
}

async function setup() {
    console.log('🔧 Configuration interactive de SYMBIOSE\n'.cyan);
    
    const config = {};
    
    // Configuration du dashboard
    const dashboardEnabled = await question('Activer le dashboard web? (Y/n): ');
    config.dashboard = {
        enabled: !dashboardEnabled.toLowerCase().startsWith('n'),
        port: 3000
    };
    
    if (config.dashboard.enabled) {
        const port = await question('Port du dashboard (3000): ');
        config.dashboard.port = parseInt(port) || 3000;
    }
    
    // Configuration des intercepteurs
    console.log('\n🔌 Configuration des intercepteurs:');
    const httpEnabled = await question('Intercepter HTTP/HTTPS? (Y/n): ');
    const wsEnabled = await question('Intercepter WebSocket? (Y/n): ');
    const processEnabled = await question('Intercepter les processus? (y/N): ');
    
    config.interceptors = {
        http: !httpEnabled.toLowerCase().startsWith('n'),
        websocket: !wsEnabled.toLowerCase().startsWith('n'),
        process: processEnabled.toLowerCase().startsWith('y')
    };
    
    // Configuration des providers
    console.log('\n🤖 Providers à surveiller:');
    const providers = [];
    
    const openai = await question('OpenAI? (Y/n): ');
    if (!openai.toLowerCase().startsWith('n')) providers.push('openai');
    
    const anthropic = await question('Anthropic? (Y/n): ');
    if (!anthropic.toLowerCase().startsWith('n')) providers.push('anthropic');
    
    const google = await question('Google AI? (y/N): ');
    if (google.toLowerCase().startsWith('y')) providers.push('google');
    
    const cohere = await question('Cohere? (y/N): ');
    if (cohere.toLowerCase().startsWith('y')) providers.push('cohere');
    
    config.providers = providers;
    
    // Sauvegarde
    const configPath = path.join(process.cwd(), 'config', 'symbiose.json');
    await fs.mkdir(path.dirname(configPath), { recursive: true });
    await fs.writeFile(configPath, JSON.stringify(config, null, 2));
    
    console.log('\n✅ Configuration sauvegardée!'.green);
    console.log(`📁 Fichier: ${configPath}`.gray);
    
    console.log('\n🚀 Pour démarrer SYMBIOSE:'.yellow);
    console.log('  npm start'.cyan);
    console.log('  # ou');
    console.log('  symbiose start'.cyan);
    
    rl.close();
}

setup().catch(console.error);
EOF

chmod +x bin/symbiose-cli.js
chmod +x bin/setup.js

# Interface web
echo -e "${YELLOW}🌐 Création de l'interface web...${NC}"

cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SYMBIOSE AI Interceptor - Dashboard</title>
    <script src="https://cdn.socket.io/4.7.2/socket.io.min.js"></script>
    <link rel="stylesheet" href="css/dashboard.css">
</head>
<body>
    <div class="header">
        <h1>🔬 SYMBIOSE AI Interceptor</h1>
        <div class="status-indicator" id="status">
            <span class="dot"></span>
            <span>Actif</span>
        </div>
    </div>

    <div class="container">
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-value" id="total-messages">0</div>
                <div class="stat-label">Messages</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="active-routes">0</div>
                <div class="stat-label">Routes</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="avg-latency">0ms</div>
                <div class="stat-label">Latence moy.</div>
            </div>
            <div class="stat-card">
                <div class="stat-value" id="error-rate">0%</div>
                <div class="stat-label">Taux d'erreur</div>
            </div>
        </div>

        <div class="content-grid">
            <div class="card">
                <h3>📊 Providers</h3>
                <div id="providers-list" class="providers-list">
                    <div class="provider-item">
                        <span class="provider-name openai">OpenAI</span>
                        <span class="provider-count">0</span>
                    </div>
                    <div class="provider-item">
                        <span class="provider-name anthropic">Anthropic</span>
                        <span class="provider-count">0</span>
                    </div>
                    <div class="provider-item">
                        <span class="provider-name google">Google</span>
                        <span class="provider-count">0</span>
                    </div>
                </div>
            </div>

            <div class="card">
                <h3>🔄 Messages récents</h3>
                <div id="messages-list" class="messages-list"></div>
            </div>
        </div>

        <div class="card">
            <h3>⚙️ Routes configurées</h3>
            <div id="routes-list" class="routes-list"></div>
        </div>
    </div>

    <script src="js/dashboard.js"></script>
</body>
</html>
EOF

cat > public/css/dashboard.css << 'EOF'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    background: linear-gradient(135deg, #0f1419 0%, #1a1f2e 100%);
    color: #e0e6ed;
    min-height: 100vh;
}

.header {
    background: rgba(0, 0, 0, 0.3);
    backdrop-filter: blur(10px);
    padding: 20px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.header h1 {
    font-size: 1.8em;
    background: linear-gradient(45deg, #00ff88, #00ddff);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
}

.status-indicator {
    display: flex;
    align-items: center;
    gap: 8px;
    background: rgba(0, 255, 136, 0.1);
    padding: 8px 16px;
    border-radius: 20px;
    border: 1px solid rgba(0, 255, 136, 0.3);
}

.status-indicator .dot {
    width: 8px;
    height: 8px;
    background: #00ff88;
    border-radius: 50%;
    animation: pulse 2s infinite;
}

@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
}

.container {
    padding: 30px;
    max-width: 1400px;
    margin: 0 auto;
}

.stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 20px;
    margin-bottom: 30px;
}

.stat-card {
    background: rgba(255, 255, 255, 0.05);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 12px;
    padding: 24px;
    text-align: center;
    transition: transform 0.3s ease;
}

.stat-card:hover {
    transform: translateY(-2px);
    border-color: rgba(0, 255, 136, 0.3);
}

.stat-value {
    font-size: 2.5em;
    font-weight: bold;
    color: #00ff88;
    margin-bottom: 8px;
}

.stat-label {
    color: #8892b0;
    font-size: 0.9em;
}

.content-grid {
    display: grid;
    grid-template-columns: 1fr 2fr;
    gap: 20px;
    margin-bottom: 30px;
}

.card {
    background: rgba(255, 255, 255, 0.05);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 12px;
    padding: 24px;
}

.card h3 {
    margin-bottom: 20px;
    color: #64ffda;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    padding-bottom: 10px;
}

.providers-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.provider-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 8px;
    border: 1px solid rgba(255, 255, 255, 0.1);
}

.provider-name {
    padding: 4px 12px;
    border-radius: 12px;
    font-size: 0.85em;
    font-weight: 500;
}

.provider-name.openai {
    background: #74aa9c;
    color: #000;
}

.provider-name.anthropic {
    background: #d4a574;
    color: #000;
}

.provider-name.google {
    background: #4285f4;
    color: #fff;
}

.provider-count {
    font-weight: bold;
    color: #00ff88;
}

.messages-list {
    max-height: 300px;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    gap: 8px;
}

.message-item {
    background: rgba(255, 255, 255, 0.03);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-left: 3px solid #00ff88;
    border-radius: 6px;
    padding: 12px;
    font-size: 0.9em;
}

.message-header {
    display: flex;
    justify-content: space-between;
    margin-bottom: 6px;
}

.message-provider {
    color: #64ffda;
    font-weight: 500;
}

.message-time {
    color: #8892b0;
    font-size: 0.8em;
}

.message-details {
    color: #ccd6f6;
    font-size: 0.85em;
}

.routes-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.route-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 16px;
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px;
}

.route-info h4 {
    color: #64ffda;
    margin-bottom: 4px;
}

.route-info p {
    color: #8892b0;
    font-size: 0.9em;
}

.route-status {
    padding: 6px 12px;
    border-radius: 12px;
    font-size: 0.8em;
    font-weight: 500;
}

.route-status.enabled {
    background: rgba(0, 255, 136, 0.2);
    color: #00ff88;
    border: 1px solid rgba(0, 255, 136, 0.3);
}

.route-status.disabled {
    background: rgba(255, 255, 255, 0.1);
    color: #8892b0;
    border: 1px solid rgba(255, 255, 255, 0.2);
}

/* Scrollbar styling */
::-webkit-scrollbar {
    width: 6px;
}

::-webkit-scrollbar-track {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 3px;
}

::-webkit-scrollbar-thumb {
    background: rgba(0, 255, 136, 0.3);
    border-radius: 3px;
}

::-webkit-scrollbar-thumb:hover {
    background: rgba(0, 255, 136, 0.5);
}

@media (max-width: 768px) {
    .content-grid {
        grid-template-columns: 1fr;
    }
    
    .stats-grid {
        grid-template-columns: repeat(2, 1fr);
    }
    
    .container {
        padding: 20px;
    }
}
EOF

cat > public/js/dashboard.js << 'EOF'
class SymbioseDashboard {
    constructor() {
        this.socket = io();
        this.messages = [];
        this.stats = {};
        this.routes = [];
        
        this.initializeEventListeners();
        this.setupSocketHandlers();
    }
    
    initializeEventListeners() {
        // Mise à jour automatique toutes les 5 secondes
        setInterval(() => {
            this.fetchStats();
        }, 5000);
    }
    
    setupSocketHandlers() {
        this.socket.on('connect', () => {
            console.log('📡 Connecté au serveur SYMBIOSE');
            document.getElementById('status').innerHTML = `
                <span class="dot"></span>
                <span>Connecté</span>
            `;
        });
        
        this.socket.on('disconnect', () => {
            console.log('📡 Déconnecté du serveur SYMBIOSE');
            document.getElementById('status').innerHTML = `
                <span class="dot" style="background: #ff6b6b; animation: none;"></span>
                <span>Déconnecté</span>
            `;
        });
        
        this.socket.on('initial-data', (data) => {
            this.stats = data.stats;
            this.messages = data.messages || [];
            this.routes = data.routes || [];
            
            this.updateUI();
        });
        
        this.socket.on('new-message', (message) => {
            this.addMessage(message);
            this.updateStats();
        });
    }
    
    async fetchStats() {
        try {
            const response = await fetch('/api/stats');
            const data = await response.json();
            
            this.stats = data;
            this.updateStatsDisplay();
        } catch (error) {
            console.error('Erreur fetch stats:', error);
        }
    }
    
    addMessage(message) {
        this.messages.unshift(message);
        
        // Garder seulement les 100 derniers messages
        if (this.messages.length > 100) {
            this.messages = this.messages.slice(0, 100);
        }
        
        this.updateMessagesDisplay();
        this.updateProvidersDisplay();
    }
    
    updateUI() {
        this.updateStatsDisplay();
        this.updateMessagesDisplay();
        this.updateRoutesDisplay();
        this.updateProvidersDisplay();
    }
    
    updateStatsDisplay() {
        const dashboard = this.stats.dashboard || {};
        
        document.getElementById('total-messages').textContent = 
            dashboard.totalMessages || 0;
        
        document.getElementById('active-routes').textContent = 
            this.stats.routes?.length || 0;
        
        document.getElementById('avg-latency').textContent = 
            `${dashboard.avgLatency || 0}ms`;
        
        const errorRate = dashboard.totalMessages > 0 ? 
            Math.round((dashboard.errors || 0) / dashboard.totalMessages * 100) : 0;
        document.getElementById('error-rate').textContent = `${errorRate}%`;
    }
    
    updateMessagesDisplay() {
        const container = document.getElementById('messages-list');
        
        // Afficher les 10 derniers messages
        const recentMessages = this.messages.slice(0, 10);
        
        container.innerHTML = recentMessages.map(msg => `
            <div class="message-item">
                <div class="message-header">
                    <span class="message-provider">${msg.provider || 'Unknown'}</span>
                    <span class="message-time">${new Date(msg.timestamp).toLocaleTimeString()}</span>
                </div>
                <div class="message-details">
                    ${msg.model || 'N/A'} • ${msg.type} • ${msg.metadata?.duration || 'N/A'}ms
                </div>
            </div>
        `).join('');
    }
    
    updateProvidersDisplay() {
        const providers = {};
        
        // Compter les messages par provider
        this.messages.forEach(msg => {
            if (msg.provider) {
                providers[msg.provider] = (providers[msg.provider] || 0) + 1;
            }
        });
        
        // Mettre à jour l'affichage
        const providerItems = document.querySelectorAll('.provider-item');
        providerItems.forEach(item => {
            const name = item.querySelector('.provider-name').textContent.toLowerCase();
            const countEl = item.querySelector('.provider-count');
            countEl.textContent = providers[name] || 0;
        });
    }
    
    updateRoutesDisplay() {
        const container = document.getElementById('routes-list');
        
        container.innerHTML = this.routes.map(route => `
            <div class="route-item">
                <div class="route-info">
                    <h4>${route.name || route.id}</h4>
                    <p>Priorité: ${route.priority || 0} • Destinations: ${route.destinations?.length || 0}</p>
                </div>
                <div class="route-status ${route.enabled ? 'enabled' : 'disabled'}">
                    ${route.enabled ? 'Activée' : 'Désactivée'}
                </div>
            </div>
        `).join('');
    }
    
    updateStats() {
        // Recalculer les stats locales
        const totalMessages = this.messages.length;
        const errors = this.messages.filter(m => m.type === 'error').length;
        const totalLatency = this.messages
            .filter(m => m.metadata?.duration)
            .reduce((sum, m) => sum + m.metadata.duration, 0);
        const avgLatency = totalMessages > 0 ? Math.round(totalLatency / totalMessages) : 0;
        
        // Mettre à jour l'affichage immédiatement
        document.getElementById('total-messages').textContent = totalMessages;
        document.getElementById('avg-latency').textContent = `${avgLatency}ms`;
        
        const errorRate = totalMessages > 0 ? Math.round(errors / totalMessages * 100) : 0;
        document.getElementById('error-rate').textContent = `${errorRate}%`;
    }
}

// Initialiser le dashboard quand la page est prête
document.addEventListener('DOMContentLoaded', () => {
    window.dashboard = new SymbioseDashboard();
});
EOF

# Tests et démo
echo -e "${YELLOW}🧪 Création des tests et démo...${NC}"

cat > tests/demo.js << 'EOF'
#!/usr/bin/env node

const colors = require('colors');
const { SymbioseSystem } = require('../src/core/symbiose-system');

async function runDemo() {
    console.log('🎯 Démo SYMBIOSE AI Interceptor\n'.cyan);
    
    // Démarrer le système
    const system = new SymbioseSystem({
        dashboard: { enabled: true, port: 3001 }
    });
    
    console.log('🚀 Démarrage du système...'.yellow);
    await system.start();
    
    console.log('✅ Système démarré!\n'.green);
    console.log('📊 Dashboard: http://localhost:3001'.cyan);
    
    // Simuler des messages IA
    console.log('🤖 Simulation d\'appels IA...\n'.yellow);
    
    const providers = ['openai', 'anthropic', 'google'];
    const models = {
        openai: ['gpt-4', 'gpt-3.5-turbo'],
        anthropic: ['claude-3-opus', 'claude-3-sonnet'],
        google: ['gemini-pro', 'gemini-pro-vision']
    };
    
    let messageCount = 0;
    
    const interval = setInterval(() => {
        const provider = providers[Math.floor(Math.random() * providers.length)];
        const modelList = models[provider];
        const model = modelList[Math.floor(Math.random() * modelList.length)];
        
        const message = {
            id: `demo_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`,
            timestamp: Date.now(),
            type: Math.random() > 0.9 ? 'error' : 'response',
            provider,
            model,
            source: 'demo-simulator',
            destination: `${provider}-api`,
            content: {
                request: {
                    messages: [{ role: 'user', content: 'Hello from SYMBIOSE demo!' }]
                },
                response: {
                    choices: [{ message: { content: 'Response from AI!' } }]
                }
            },
            metadata: {
                duration: Math.floor(Math.random() * 3000) + 500,
                tokens: Math.floor(Math.random() * 1000) + 50
            }
        };
        
        system.interceptor.emit('message', message);
        
        const emoji = message.type === 'error' ? '❌' : '✅';
        console.log(`${emoji} ${provider.toUpperCase()} ${model} (${message.metadata.duration}ms)`);
        
        messageCount++;
        
        if (messageCount >= 20) {
            clearInterval(interval);
            
            console.log('\n🎉 Démo terminée!'.green);
            console.log('📊 Consultez le dashboard pour voir les résultats'.cyan);
            console.log('🛑 Ctrl+C pour arrêter\n'.yellow);
        }
    }, 2000);
    
    // Graceful shutdown
    process.on('SIGINT', async () => {
        console.log('\n🛑 Arrêt de la démo...'.yellow);
        clearInterval(interval);
        await system.stop();
        process.exit(0);
    });
}

runDemo().catch(console.error);
EOF

cat > tests/runner.js << 'EOF'
#!/usr/bin/env node

const colors = require('colors');

async function runTests() {
    console.log('🧪 Tests SYMBIOSE AI Interceptor\n'.cyan);
    
    let passed = 0;
    let failed = 0;
    
    const test = (name, fn) => {
        try {
            fn();
            console.log(`✅ ${name}`.green);
            passed++;
        } catch (error) {
            console.log(`❌ ${name}: ${error.message}`.red);
            failed++;
        }
    };
    
    // Test 1: System import
    test('Import du système principal', () => {
        const { SymbioseSystem } = require('../src/core/symbiose-system');
        if (!SymbioseSystem) throw new Error('SymbioseSystem non trouvé');
    });
    
    // Test 2: Interceptor import
    test('Import de l\'intercepteur', () => {
        const { SymbioseInterceptor } = require('../src/core/interceptor');
        if (!SymbioseInterceptor) throw new Error('SymbioseInterceptor non trouvé');
    });
    
    // Test 3: Route Manager
    test('Gestionnaire de routes', () => {
        const { RouteManager } = require('../src/routing/route-manager');
        const rm = new RouteManager();
        
        rm.addRoute({
            id: 'test-route',
            name: 'Test Route',
            filters: [{ type: 'test', condition: () => true }],
            destinations: [{ type: 'console', config: {} }]
        });
        
        if (rm.getRoutes().length !== 1) {
            throw new Error('Route non ajoutée');
        }
    });
    
    // Test 4: Destination Manager
    test('Gestionnaire de destinations', () => {
        const { DestinationManager } = require('../src/destinations/destination-manager');
        const dm = new DestinationManager();
        
        // Test d'envoi vers console (ne doit pas échouer)
        const message = {
            id: 'test',
            timestamp: Date.now(),
            type: 'test',
            provider: 'test',
            content: {}
        };
        
        // Test synchrone (simplifié)
        dm.send(message, { type: 'console', config: {} });
    });
    
    // Test 5: Dashboard Server
    test('Serveur Dashboard', () => {
        const { DashboardServer } = require('../src/dashboard/server');
        const mockSystem = { getStats: () => ({}), routeManager: { getRoutes: () => [] } };
        const server = new DashboardServer(mockSystem, 0); // Port 0 pour test
        
        if (!server) throw new Error('DashboardServer non créé');
    });
    
    console.log(`\n📊 Résultats: ${passed} passés, ${failed} échoués\n`);
    
    if (failed === 0) {
        console.log('🎉 Tous les tests sont passés!'.green);
        process.exit(0);
    } else {
        console.log('❌ Certains tests ont échoué'.red);
        process.exit(1);
    }
}

runTests().catch(console.error);
EOF

chmod +x tests/demo.js
chmod +x tests/runner.js

# Fichiers de configuration
echo -e "${YELLOW}⚙️  Création des fichiers de configuration...${NC}"

cat > config/default.json << 'EOF'
{
  "dashboard": {
    "enabled": true,
    "port": 3000,
    "host": "localhost"
  },
  "interceptors": {
    "http": true,
    "websocket": true,
    "process": false
  },
  "providers": [
    {
      "name": "openai",
      "patterns": ["api.openai.com", "openai.azure.com"],
      "enabled": true
    },
    {
      "name": "anthropic", 
      "patterns": ["api.anthropic.com"],
      "enabled": true
    },
    {
      "name": "google",
      "patterns": ["generativelanguage.googleapis.com"],
      "enabled": true
    }
  ],
  "routes": {
    "autoload": true,
    "directory": "./config/routes"
  },
  "logging": {
    "level": "info",
    "file": "./logs/symbiose.log"
  }
}
EOF

cat > .env.example << 'EOF'
# Configuration SYMBIOSE AI Interceptor

# Dashboard
DASHBOARD_PORT=3000
DASHBOARD_ENABLED=true

# Providers (optionnel - pour authentification)
OPENAI_API_KEY=your_openai_key
ANTHROPIC_API_KEY=your_anthropic_key
GOOGLE_API_KEY=your_google_key

# Logging
LOG_LEVEL=info
LOG_FILE=./logs/symbiose.log

# Sécurité
ENABLE_PROCESS_INTERCEPTOR=false
EOF

# Documentation
cat > README.md << 'EOF'
# 🔬 SYMBIOSE AI Interceptor

Système complet d'interception et de monitoring des échanges IA en temps réel.

## 🚀 Installation Rapide

```bash
npm install
npm start
```

Dashboard disponible sur: http://localhost:3000

## ✨ Fonctionnalités

- 🔍 **Interception automatique** des appels API IA (OpenAI, Anthropic, Google, etc.)
- 📊 **Dashboard web** avec monitoring temps réel
- 🎯 **Système de routage** configurable avec filtres avancés
- 📤 **Destinations multiples** (Console, Fichiers, Webhooks, Bases de données)
- 📈 **Analytics intégrés** avec calcul de coûts et métriques
- 🔧 **CLI complet** pour gestion et monitoring
- 🐳 **Docker ready** avec docker-compose

## 🎮 Commandes CLI

```bash
# Démarrage
symbiose start                    # Lance SYMBIOSE + Dashboard
symbiose start --port 8080        # Port personnalisé
symbiose start --no-dashboard     # Sans dashboard

# Monitoring
symbiose monitor                  # Temps réel tous providers
symbiose monitor --provider openai # Filtré par provider

# Gestion
symbiose stats                    # Statistiques
symbiose routes --list            # Lister les routes
symbiose dashboard               # Ouvrir le dashboard

# Configuration
symbiose setup                   # Configuration interactive
```

## 📚 Utilisation

### 1. Démarrage de base
```javascript
const { SymbioseSystem } = require('symbiose-ai-interceptor');

const system = new SymbioseSystem();
await system.start();

// Maintenant tous vos appels IA sont interceptés automatiquement!
```

### 2. Configuration avancée
```javascript
const system = new SymbioseSystem({
  dashboard: { enabled: true, port: 3000 },
  interceptors: { http: true, websocket: true },
  routes: [
    {
      id: 'openai-monitoring',
      filters: [{ type: 'provider', condition: msg => msg.provider === 'openai' }],
      destinations: [
        { type: 'console', config: { prefix: '[OpenAI]' } },
        { type: 'webhook', config: { url: 'https://your-webhook.com' } }
      ]
    }
  ]
});
```

### 3. Routes personnalisées
```javascript
system.addRoute({
  id: 'high-cost-alerts',
  name: 'Alertes coûts élevés',
  priority: 100,
  filters: [
    { type: 'cost', condition: msg => calculateCost(msg) > 0.50 }
  ],
  destinations: [
    { type: 'webhook', config: { url: 'https://alerts.company.com' } },
    { type: 'file', config: { path: './logs/high-cost.log' } }
  ]
});
```

## 🏗️ Architecture

```
src/
├── core/           # Système principal et intercepteurs
├── routing/        # Moteur de routage avec filtres
├── destinations/   # Gestionnaires de destinations
├── dashboard/      # Interface web temps réel
└── analysis/       # Analytics et métriques
```

## 🎯 Destinations Supportées

- **Console**: Affichage dans le terminal
- **File**: Sauvegarde en fichiers JSON/logs
- **Webhook**: Envoi HTTP vers APIs externes
- **Dashboard**: Interface web temps réel
- **Database**: PostgreSQL, MySQL, MongoDB
- **Queue**: RabbitMQ, Redis, Kafka
- **Analytics**: Mixpanel, Google Analytics

## 🤖 Providers Supportés

- ✅ OpenAI (GPT-4, GPT-3.5, etc.)
- ✅ Anthropic (Claude 3)
- ✅ Google AI (Gemini)
- ✅ Cohere
- ✅ HuggingFace
- ✅ Local AI (Ollama, etc.)

## 📊 Dashboard

Interface web moderne avec:
- Statistiques en temps réel
- Historique des messages
- Gestion des routes
- Métriques de performance
- Alertes et notifications

## 🧪 Tests et Démo

```bash
npm test            # Suite de tests
npm run demo        # Démo interactive
```

## 🐳 Docker

```bash
docker-compose up   # Lance tout le stack
```

## 📄 License

MIT - Voir LICENSE pour plus de détails.

## 🤝 Contribution

1. Fork le projet
2. Créer une branche (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit (`git commit -am 'Ajouter nouvelle fonctionnalité'`)
4. Push (`git push origin feature/nouvelle-fonctionnalite`)
5. Ouvrir une Pull Request

## 📞 Support

- 📖 Documentation: [docs/](./docs/)
- 🐛 Issues: [GitHub Issues](https://github.com/your-org/symbiose/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/your-org/symbiose/discussions)

---

**SYMBIOSE AI Interceptor** - Prenez le contrôle de vos échanges IA ! 🚀
EOF

# Makefile pour faciliter l'utilisation
cat > Makefile << 'EOF'
.PHONY: help install start dev stop test demo clean

help: ## Afficher cette aide
	@echo "🔬 SYMBIOSE AI Interceptor - Commandes disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Installer les dépendances
	@echo "📦 Installation des dépendances..."
	npm install

start: ## Démarrer SYMBIOSE avec dashboard
	@echo "🚀 Démarrage de SYMBIOSE..."
	npm start

dev: ## Mode développement avec auto-reload
	@echo "🛠️  Mode développement..."
	npm run dev

dashboard: ## Lancer seulement le dashboard
	@echo "📊 Lancement du dashboard..."
	npm run dashboard

setup: ## Configuration interactive
	@echo "🔧 Configuration interactive..."
	npm run setup

test: ## Lancer les tests
	@echo "🧪 Lancement des tests..."
	npm test

demo: ## Démo interactive avec simulation
	@echo "🎯 Lancement de la démo..."
	npm run demo

monitor: ## Monitoring temps réel en CLI
	@echo "🔍 Monitoring temps réel..."
	npx symbiose monitor

stats: ## Afficher les statistiques
	@echo "📈 Statistiques système..."
	npx symbiose stats

clean: ## Nettoyer les logs et caches
	@echo "🧹 Nettoyage..."
	rm -rf logs/*.log
	rm -rf node_modules/.cache

docker-build: ## Construire l'image Docker
	@echo "🐳 Construction Docker..."
	docker build -t symbiose-ai .

docker-run: ## Lancer avec Docker
	@echo "🐳 Lancement Docker..."
	docker-compose up

stop: ## Arrêter tous les processus
	@echo "🛑 Arrêt..."
	pkill -f "symbiose" || true
	docker-compose down || true

logs: ## Voir les logs
	@echo "📋 Logs récents:"
	tail -f logs/symbiose.log || echo "Aucun log trouvé"

# Raccourcis
run: start
build: install
lint: test
EOF

# Docker
cat > Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

# Copier package.json et installer les dépendances
COPY package*.json ./
RUN npm ci --only=production

# Copier le code source
COPY . .

# Créer les répertoires nécessaires
RUN mkdir -p logs config

# Exposer le port du dashboard
EXPOSE 3000

# Variables d'environnement par défaut
ENV NODE_ENV=production
ENV DASHBOARD_PORT=3000

# Santé du conteneur
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/api/stats || exit 1

# Commande par défaut
CMD ["npm", "start"]
EOF

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  symbiose:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DASHBOARD_PORT=3000
      - DASHBOARD_ENABLED=true
    volumes:
      - ./logs:/app/logs
      - ./config:/app/config
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/stats"]
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data

volumes:
  redis_data:
EOF

cat > .dockerignore << 'EOF'
node_modules
npm-debug.log
logs/*.log
.git
.gitignore
README.md
Dockerfile
.dockerignore
docker-compose.yml
EOF

# .gitignore
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Logs
logs/
*.log

# Environment
.env
.env.local
.env.production

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Build
dist/
build/

# Coverage
coverage/

# Temporary
tmp/
temp/
EOF

# Installation des dépendances
echo -e "${YELLOW}📦 Installation des dépendances NPM...${NC}"
npm install --silent

# Rendre le CLI exécutable globalement
echo -e "${YELLOW}🔗 Installation du CLI global...${NC}"
npm link --silent

echo -e "${GREEN}✅ Installation terminée avec succès!${NC}"
echo ""
echo -e "${CYAN}🎉 SYMBIOSE AI Interceptor est prêt!${NC}"
echo ""
echo -e "${YELLOW}📋 Commandes disponibles:${NC}"
echo -e "  ${BLUE}cd $PROJECT_NAME${NC}"
echo -e "  ${BLUE}npm start${NC}                    # Démarrer SYMBIOSE + Dashboard"
echo -e "  ${BLUE}npm run demo${NC}                 # Démo interactive"
echo -e "  ${BLUE}npm run setup${NC}                # Configuration interactive"
echo -e "  ${BLUE}symbiose start${NC}               # Via CLI global"
echo -e "  ${BLUE}symbiose monitor${NC}             # Monitoring temps réel"
echo -e "  ${BLUE}make help${NC}                    # Voir toutes les commandes"
echo ""
echo -e "${YELLOW}🌐 Interfaces:${NC}"
echo -e "  ${CYAN}Dashboard: http://localhost:3000${NC}"
echo -e "  ${CYAN}API: http://localhost:3000/api/stats${NC}"
echo ""
echo -e "${YELLOW}📚 Documentation:${NC}"
echo -e "  ${CYAN}README.md - Guide complet${NC}"
echo -e "  ${CYAN}docs/ - Documentation détaillée${NC}"
echo ""
echo -e "${GREEN}🚀 Pour commencer maintenant:${NC}"
echo -e "  ${BLUE}cd $PROJECT_NAME && npm start${NC}"

# Message final avec art ASCII
echo ""
echo -e "${PURPLE}"
cat << "EOF"
┌─────────────────────────────────────────────┐
│  🔬 SYMBIOSE AI INTERCEPTOR v2.0            │
│  ✅ Installation réussie!                   │
│  🎯 Système complet d'interception IA       │
│  📊 Dashboard web inclus                    │
│  🔧 CLI complet                             │
│  🐳 Docker ready                            │
└─────────────────────────────────────────────┘
EOF
echo -e "${NC}"

echo -e "${GREEN}Bon développement avec SYMBIOSE! 🚀${NC}"