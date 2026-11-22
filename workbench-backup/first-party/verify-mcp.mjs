import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const java = join(root, 'jdk');
const child = spawn(process.execPath, [join(root, 'runtime-packed', 'scripts', 'rea.mjs'), 'mcp'], {
  env: { ...process.env, JAVA_HOME: java, REA_JADX_MCP_JAR: join(root, 'downloads', 'jadx-headless-mcp-0.7.1-all.jar'), PATH: `${join(java, 'bin')};${process.env.PATH}` },
  stdio: ['pipe', 'pipe', 'pipe'],
});
let done = false;
const timer = setTimeout(() => finish('MCP handshake timed out', 1), 60000);
function finish(message, code) {
  if (done) return;
  done = true;
  clearTimeout(timer);
  console.log(message);
  child.kill();
  process.exitCode = code;
}
child.on('error', error => finish(`MCP launch failed: ${error.message}`, 1));
child.on('exit', code => { if (!done) finish(`MCP exited before verification (${code})`, 1); });
createInterface({ input: child.stdout }).on('line', line => {
  let message;
  try { message = JSON.parse(line); } catch { return; }
  if (message.id === 1 && message.result) {
    child.stdin.write(`${JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' })}\n`);
    child.stdin.write(`${JSON.stringify({ jsonrpc: '2.0', id: 2, method: 'tools/list', params: {} })}\n`);
  } else if (message.id === 2 && message.result) {
    const tools = message.result.tools || [];
    const android = tools.some(tool => tool.name === 'inspect_android_package');
    finish(`MCP initialized; ${tools.length} tools listed; Android package tool ${android ? 'available' : 'missing'}.`, android ? 0 : 1);
  } else if (message.error) finish(`MCP error: ${message.error.message}`, 1);
});
child.stdin.write(`${JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'local-readiness-check', version: '1.0.0' } } })}\n`);
