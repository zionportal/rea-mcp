const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = __dirname;
const sample = path.join(root, 'verification-godot');
const compiled = path.join(sample, 'compiled');
const recovered = path.join(sample, 'recovered');
for (const dir of [sample, compiled, recovered]) fs.mkdirSync(dir, { recursive: true });
const script = path.join(sample, 'example.gd');
fs.writeFileSync(script, 'extends Node\n\nfunc verification_message():\n    return "ava_godot_fixture"\n');
const exe = path.join(root, 'godot-re-tools', 'gdre_tools.exe');
function run(args) {
  const result = spawnSync(exe, ['--headless', ...args], { encoding: 'utf8', windowsHide: true, timeout: 30000 });
  if (result.error || result.status !== 0) throw new Error(`Godot command failed (${result.status}): ${result.error?.message || ''} ${(result.stdout || '').slice(-800)} ${(result.stderr || '').slice(-800)}`);
}
run([`--compile=${script}`, '--bytecode=4.3.0', `--output=${compiled}`]);
const bytecode = path.join(compiled, 'example.gdc');
if (!fs.existsSync(bytecode)) throw new Error('Compiled bytecode was not produced');
run([`--decompile=${bytecode}`, '--bytecode=4.3.0', `--output=${recovered}`]);
const source = fs.readFileSync(path.join(recovered, 'example.gd'), 'utf8');
if (!source.includes('ava_godot_fixture')) throw new Error('Recovered source did not contain fixture marker');
console.log('Godot RE Tools: compiled and decompiled local GDScript fixture.');
