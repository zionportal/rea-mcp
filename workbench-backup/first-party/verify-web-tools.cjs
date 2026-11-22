const { createServer } = require('node:http');
const { spawn } = require('node:child_process');
const { mkdtemp, readFile, readdir } = require('node:fs/promises');
const path = require('node:path');

process.env.PLAYWRIGHT_BROWSERS_PATH = path.join(__dirname, 'playwright', 'browsers');
const { chromium } = require('./playwright/node_modules/playwright');
const server = createServer((req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  if (req.url === '/child.html') return res.end('<h1>LOCAL_FIXTURE_CHILD</h1>');
  if (req.url === '/robots.txt') { res.statusCode = 404; return res.end(''); }
  if (req.url !== '/' && req.url !== '/index.html') { res.statusCode = 404; return res.end(''); }
  res.end('<h1>LOCAL_FIXTURE_HOME</h1><a href="/child.html">Child</a><span id="dynamic"></span><script>document.querySelector("#dynamic").textContent="LOCAL_DYNAMIC_READY"</script>');
});

async function collectHtml(folder) {
  const result = [];
  for (const entry of await readdir(folder, { withFileTypes: true })) {
    const target = path.join(folder, entry.name);
    if (entry.isDirectory()) result.push(...await collectHtml(target));
    else if (/\.html?$/i.test(entry.name)) result.push(await readFile(target, 'utf8'));
  }
  return result;
}

async function main() {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const url = `http://127.0.0.1:${server.address().port}/index.html`;
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage();
    await page.goto(url);
    if (await page.locator('#dynamic').textContent() !== 'LOCAL_DYNAMIC_READY') throw new Error('Playwright dynamic rendering failed');
    console.log('Playwright: local Chromium rendered dynamic fixture.');
  } finally { await browser.close(); }
  const output = await mkdtemp(path.join(__dirname, 'web-tool-check-'));
  const exe = path.join(__dirname, 'httrack', 'httrack', 'httrack.exe');
  const exit = await new Promise((resolve, reject) => {
    const child = spawn(exe, [url, '-O', output, '-q', '-r2'], { stdio: 'ignore' });
    const timer = setTimeout(() => { child.kill(); reject(new Error('HTTrack test timed out')); }, 60000);
    child.on('error', error => { clearTimeout(timer); reject(error); });
    child.on('exit', code => { clearTimeout(timer); resolve(code); });
  });
  if (exit !== 0) throw new Error(`HTTrack exited ${exit}`);
  const files = await collectHtml(output);
  if (!files.some(file => file.includes('LOCAL_FIXTURE_HOME')) || !files.some(file => file.includes('LOCAL_FIXTURE_CHILD'))) throw new Error('HTTrack did not mirror both fixture pages');
  console.log('HTTrack: mirrored two linked pages from a local fixture.');
  console.log(`Fixture output: ${output}`);
}

main().catch(error => { console.error(error.message); process.exitCode = 1; }).finally(() => server.close());
