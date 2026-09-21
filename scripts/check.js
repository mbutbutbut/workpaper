// Quick checks that run on every pull request (and locally: node scripts/check.js).
'use strict';
const fs = require('fs'), path = require('path'), vm = require('vm');
let bad = 0;
const fail = (m) => { bad++; console.log('FAIL  ' + m); };
const ok = (m) => console.log('ok    ' + m);

// 1. The app's script must parse. A typo here blanks the whole page.
const html = fs.readFileSync('index.html', 'utf8');
const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map(m => m[1]);
if (!scripts.length) fail('index.html has no inline script');
scripts.forEach((s, i) => { try { new vm.Script(s); ok('index.html script ' + (i + 1) + ' parses'); } catch (e) { fail('index.html script ' + (i + 1) + ': ' + e.message); } });
['config.js', 'api/team.js', 'mcp/server.js'].forEach(f => {
  try { new vm.Script(fs.readFileSync(f, 'utf8').replace(/^#!.*\n/, '')); ok(f + ' parses'); } catch (e) { fail(f + ': ' + e.message); }
});

// 2. No secrets in the repo. The publishable key (sb_publishable_...) is meant to be public; anything else is not.
const skip = new Set(['.git', 'node_modules', '.impeccable', '.claude', '.vercel']);
const patterns = [
  [/sb_secret_[A-Za-z0-9_-]{10,}/, 'Supabase secret key'],
  [/eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}/, 'JWT / service key'],
  [/-----BEGIN [A-Z ]*PRIVATE KEY-----/, 'private key'],
  [/"WORKPAPER_PASSWORD"\s*:\s*"(?!your admin password)[^"]+"/, 'a real password in an MCP config'],
  [/postgres(ql)?:\/\/[^:\s]+:[^@\s]{6,}@/, 'database connection string with a password']
];
function walk(d) {
  fs.readdirSync(d, { withFileTypes: true }).forEach(e => {
    if (skip.has(e.name)) return;
    const p = path.join(d, e.name);
    if (e.isDirectory()) return walk(p);
    if (p === path.join('tests', 'team.test.js') || p === path.join('scripts', 'check.js')) return;
    if (!/\.(js|html|md|sql|json|yml|yaml|txt|css)$/.test(e.name)) return;
    const t = fs.readFileSync(p, 'utf8');
    patterns.forEach(([re, name]) => { if (re.test(t)) fail(p + ' looks like it contains ' + name); });
  });
}
walk('.');
if (!bad) ok('no secrets found');

console.log(bad ? '\n' + bad + ' check(s) failed' : '\nAll checks passed');
process.exit(bad ? 1 : 0);
