# SYMBIOSE AI Interceptor

> Systeme professionnel d'interception, monitoring et audit des appels API d'Intelligence Artificielle

![Version](https://img.shields.io/badge/version-3.0-blue)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Windows-lightgrey)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Multi-Provider Support**: OpenAI, Anthropic Claude, Google Gemini, Cohere, HuggingFace
- **Real-time Monitoring**: Dashboard web avec metriques en temps reel
- **Network Interception**: Capture transparente HTTP/HTTPS/WebSocket
- **Analytics**: Statistiques d'usage, latences, couts estimes
- **Alerting**: Notifications Telegram/Discord/Webhook
- **Export**: JSON, CSV, SQL pour analyse

## Quick Start

### Linux (Recommended)

```bash
# Installation complete
curl -sSL https://raw.githubusercontent.com/Turbo31150/INTERCEPTOR-/main/symbiose_full_installer.sh | bash

# Ou cloner et installer
git clone https://github.com/Turbo31150/INTERCEPTOR-.git
cd INTERCEPTOR-
chmod +x symbiose_full_installer.sh
./symbiose_full_installer.sh
```

### Windows (PowerShell)

```powershell
# Cloner le repo
git clone https://github.com/Turbo31150/INTERCEPTOR-.git
cd INTERCEPTOR-

# Installer les dependances
npm install

# Lancer
npm start
```

## Architecture

```
+-------------------+    +-------------------+    +-------------------+
|   Applications    |    |     SYMBIOSE      |    |    AI APIs        |
|   (AI Clients)    |--->|    Interceptor    |--->| OpenAI/Claude     |
|                   |    |   192.168.1.x     |    | Gemini/Cohere     |
+-------------------+    +-------------------+    +-------------------+
                               |
                               v
                        +-------------------+
                        |    Dashboard      |
                        |   :3000 / :3001   |
                        +-------------------+
```

## Configuration

```yaml
# config.yaml
interceptor:
  port: 8080
  ssl: true

providers:
  - openai
  - anthropic
  - google
  - cohere

destinations:
  - console
  - file: /var/log/symbiose/
  - webhook: https://your-webhook.com
  - telegram:
      bot_token: "YOUR_BOT_TOKEN"
      chat_id: "YOUR_CHAT_ID"

dashboard:
  port: 3000
  auth: true
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/intercepts` | GET | Liste des interceptions |
| `/api/stats` | GET | Statistiques globales |
| `/api/providers` | GET | Providers actifs |
| `/api/export` | POST | Export des donnees |
| `/ws` | WebSocket | Stream temps reel |

## Integration Trading AI Ultimate

Ce projet s'integre avec [Trading AI Ultimate](https://github.com/Turbo31150/trading-ai-n8n-workflows):

```javascript
// Dans votre app Electron ou n8n
const interceptor = require('symbiose-interceptor');

// Capturer tous les appels IA
interceptor.on('intercept', (data) => {
  console.log(`[${data.provider}] ${data.model} - ${data.latency}ms`);
  // Envoyer a Telegram, n8n, etc.
});
```

## Commandes CLI

```bash
# Status du service
symbiose status

# Voir les logs en temps reel
symbiose logs -f

# Exporter les interceptions
symbiose export --format json --output ./exports/

# Statistiques
symbiose stats --period 24h

# Redemarrer
symbiose restart
```

## Screenshots

### Dashboard Principal
- Metriques temps reel
- Graphiques d'usage par provider
- Timeline des appels
- Alertes actives

### Analytics
- Cout estime par provider
- Latences moyennes
- Volume d'appels
- Tokens utilises

## Roadmap

- [ ] Support Windows natif (service)
- [ ] Integration Docker Compose
- [ ] Plugin VSCode
- [ ] Mobile app (React Native)
- [ ] Machine Learning anomaly detection

## Contributing

1. Fork le projet
2. Creer une branche (`git checkout -b feature/amazing`)
3. Commit (`git commit -m 'Add amazing feature'`)
4. Push (`git push origin feature/amazing`)
5. Ouvrir une Pull Request

## License

MIT License - voir [LICENSE](LICENSE)

## Author

**Turbo31150** - Trading AI Systems

---

*Partie du projet Trading AI Ultimate - Multi-IA Consensus System*
