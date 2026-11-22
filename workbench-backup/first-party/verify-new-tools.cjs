const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = __dirname;
function run(exe, args, cwd) {
  const result = spawnSync(exe, args, { cwd, encoding: 'utf8', windowsHide: true, timeout: 60000, maxBuffer: 5 * 1024 * 1024 });
  if (result.error || result.status !== 0) throw new Error(`${path.basename(exe)} failed (${result.status}): ${result.error?.message || ''} ${(result.stderr || '').slice(-800)}`);
  return result.stdout || '';
}
const dependencies = path.join(root, 'dependencies', 'Dependencies.exe');
const imports = run(dependencies, ['-imports', path.join(root, '7zip', '7z.exe')], path.dirname(dependencies));
if (!/USER32\.dll/i.test(imports)) throw new Error('Expected import not found in Dependencies output');
console.log('Dependencies: read imports from local 7-Zip executable.');
const out = path.join(root, 'verification-dnspy');
if (fs.existsSync(out)) throw new Error('Verification output exists; refusing to overwrite');
const dnspy = path.join(root, 'dnspyex', 'dnSpy.Console.exe');
run(dnspy, ['--no-resources', '--no-baml', '--no-resx', '-o', out, path.join(root, 'dnspyex', 'bin', 'MessagePack.Annotations.dll')], path.dirname(dnspy));
function countCs(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).reduce((sum, entry) => sum + (entry.isDirectory() ? countCs(path.join(dir, entry.name)) : Number(entry.name.endsWith('.cs'))), 0);
}
const count = countCs(out);
if (!count) throw new Error('dnSpy did not produce C# files');
console.log(`dnSpyEx: decompiled local managed test assembly into ${count} C# files.`);
