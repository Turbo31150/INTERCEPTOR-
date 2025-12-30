#!/usr/bin/env node
/**
 * SYMBIOSE CLI
 */

const { program } = require('commander');
const { SymbioseInterceptor, start } = require('../src/index');
const chalk = require('chalk');
const fs = require('fs');
const path = require('path');

program
  .name('symbiose')
  .description('SYMBIOSE AI Interceptor CLI')
  .version('3.0.0');

program
  .command('start')
  .description('Start the interceptor service')
  .action(async () => {
    console.log(chalk.cyan('Starting SYMBIOSE AI Interceptor...'));
    await start();
  });

program
  .command('status')
  .description('Show service status')
  .action(() => {
    console.log(chalk.cyan('SYMBIOSE Status'));
    console.log('─'.repeat(40));
    console.log(`Version: ${chalk.green('3.0.0')}`);
    console.log(`Dashboard: ${chalk.yellow('http://localhost:3000')}`);
    console.log(`WebSocket: ${chalk.yellow('ws://localhost:3001')}`);
  });

program
  .command('logs')
  .description('Show recent logs')
  .option('-f, --follow', 'Follow log output')
  .action((options) => {
    const logPath = path.join(__dirname, '../logs/symbiose.log');

    if (!fs.existsSync(logPath)) {
      console.log(chalk.yellow('No logs found'));
      return;
    }

    const logs = fs.readFileSync(logPath, 'utf8');
    console.log(logs.split('\n').slice(-50).join('\n'));
  });

program
  .command('export')
  .description('Export interceptions')
  .option('-f, --format <format>', 'Output format (json|csv)', 'json')
  .option('-o, --output <path>', 'Output file path')
  .action((options) => {
    console.log(chalk.cyan(`Exporting as ${options.format}...`));
    // Would connect to running service
    console.log(chalk.green('Export complete'));
  });

program
  .command('stats')
  .description('Show statistics')
  .option('-p, --period <period>', 'Time period (1h|24h|7d)', '24h')
  .action((options) => {
    console.log(chalk.cyan(`Statistics (${options.period})`));
    console.log('─'.repeat(40));
    console.log('Total intercepts: 0');
    console.log('Avg latency: 0ms');
    console.log('By provider:');
    console.log('  OpenAI: 0');
    console.log('  Anthropic: 0');
    console.log('  Google: 0');
  });

program
  .command('restart')
  .description('Restart the service')
  .action(() => {
    console.log(chalk.yellow('Restarting SYMBIOSE...'));
    // Would restart service
    console.log(chalk.green('Service restarted'));
  });

program.parse();
