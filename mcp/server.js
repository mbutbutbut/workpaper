#!/usr/bin/env node
// Workpaper MCP server (read-only). Lets Claude read the checklist over stdio.
// It signs in as a real Workpaper user, so the database's own rules decide what it can see.
// Settings come from the environment (set them in your MCP client config, never in this file):
//   WORKPAPER_SUPABASE_URL, WORKPAPER_SUPABASE_KEY (the publishable key), WORKPAPER_EMAIL, WORKPAPER_PASSWORD
'use strict';

const URL_ = (process.env.WORKPAPER_SUPABASE_URL || '').replace(/\/$/, '');
const KEY = process.env.WORKPAPER_SUPABASE_KEY || '';
const EMAIL = process.env.WORKPAPER_EMAIL || '';
const PASSWORD = process.env.WORKPAPER_PASSWORD || '';
const MAX_ROWS = 200;

let token = null, tokenExpires = 0;

async function signIn() {
  if (token && Date.now() < tokenExpires - 60000) return token;
  if (!URL_ || !KEY || !EMAIL || !PASSWORD) throw new Error('Set WORKPAPER_SUPABASE_URL, WORKPAPER_SUPABASE_KEY, WORKPAPER_EMAIL and WORKPAPER_PASSWORD.');
  const r = await fetch(URL_ + '/auth/v1/token?grant_type=password', {
    method: 'POST', headers: { apikey: KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: EMAIL, password: PASSWORD })
  });
  const j = await r.json().catch(() => ({}));
  if (!r.ok || !j.access_token) throw new Error('Sign-in failed. Check the email and password.');
  token = j.access_token; tokenExpires = Date.now() + (j.expires_in || 3600) * 1000;
  return token;
}

// Read-only: only GET requests are ever made to the data API.
async function read(path) {
  const t = await signIn();
  const r = await fetch(URL_ + '/rest/v1/' + path, { headers: { apikey: KEY, Authorization: 'Bearer ' + t } });
  if (!r.ok) throw new Error('Could not read data (' + r.status + ').');
  return r.json();
}

const enc = encodeURIComponent;
const ITEM_COLS = 'id,request_id,no,item_date,description,memo,amount,source,owner,status,note,reviewed,sent_back,fingerprint';
const STATUS_NAMES = { waiting: 'Waiting on me', hubdoc: 'In Hubdoc', jeff: 'With Jeff', missing: 'No document', explained: 'Explained' };

async function latestRequest() {
  const rows = await read('requests?select=id,name,imported_at&order=imported_at.desc&limit=1');
  return rows[0] || null;
}
function shape(i) { return Object.assign({}, i, { status_label: STATUS_NAMES[i.status] || i.status }); }

const tools = {
  list_requests: {
    description: 'List the imported requests (cycles), newest first.',
    input: { type: 'object', properties: {} },
    run: async () => read('requests?select=id,name,imported_at&order=imported_at.desc&limit=50')
  },
  list_items: {
    description: 'List checklist items. Defaults to the newest request. Filter by status (waiting, hubdoc, jeff, missing, explained), owner (me, jeff), or text in the description. Returns at most ' + MAX_ROWS + ' rows.',
    input: { type: 'object', properties: {
      request_id: { type: 'string', description: 'Request id; omit for the newest request.' },
      status: { type: 'string', enum: Object.keys(STATUS_NAMES) },
      owner: { type: 'string', enum: ['me', 'jeff'] },
      search: { type: 'string', description: 'Text to find in the description.' },
      sent_back_only: { type: 'boolean', description: 'Only items the bookkeeper sent back.' }
    } },
    run: async (a) => {
      let rid = a.request_id;
      if (!rid) { const r = await latestRequest(); if (!r) return []; rid = r.id; }
      let q = 'items?select=' + ITEM_COLS + '&request_id=eq.' + enc(rid) + '&order=no.asc&limit=' + MAX_ROWS;
      if (a.status) q += '&status=eq.' + enc(a.status);
      if (a.owner) q += '&owner=eq.' + enc(a.owner);
      if (a.sent_back_only) q += '&sent_back=eq.true';
      if (a.search) q += '&description=ilike.' + enc('*' + String(a.search).replace(/[*,()]/g, ' ') + '*');
      return (await read(q)).map(shape);
    }
  },
  summary: {
    description: 'Counts by status and owner for a request (defaults to the newest), plus how many are reviewed and sent back.',
    input: { type: 'object', properties: { request_id: { type: 'string' } } },
    run: async (a) => {
      let rid = a.request_id, name = '';
      if (!rid) { const r = await latestRequest(); if (!r) return { message: 'No requests yet.' }; rid = r.id; name = r.name; }
      const rows = await read('items?select=status,owner,reviewed,sent_back&request_id=eq.' + enc(rid) + '&limit=5000');
      const by = {}; let jeff = 0, reviewed = 0, back = 0;
      rows.forEach(r => { const k = STATUS_NAMES[r.status] || r.status; by[k] = (by[k] || 0) + 1; if (r.owner === 'jeff') jeff++; if (r.reviewed) reviewed++; if (r.sent_back) back++; });
      return { request: name || rid, total: rows.length, by_status: by, owned_by_jeff: jeff, reviewed, sent_back: back };
    }
  },
  get_conversation: {
    description: 'Read the messages on one item, by the item id.',
    input: { type: 'object', properties: { item_id: { type: 'string' } }, required: ['item_id'] },
    run: async (a) => {
      const it = await read('items?select=id,no,description,note,fingerprint&id=eq.' + enc(a.item_id) + '&limit=1');
      if (!it[0]) return { message: 'Item not found (or you cannot see it).' };
      const msgs = await read('comments?select=role,kind,body,created_at,removed&fingerprint=eq.' + enc(it[0].fingerprint) + '&order=created_at.asc&limit=200');
      return { item: { id: it[0].id, no: it[0].no, description: it[0].description, note: it[0].note }, messages: msgs.map(m => ({ from: m.role, kind: m.kind, text: m.removed ? '(removed)' : m.body, at: m.created_at })) };
    }
  }
};

// Minimal MCP over stdio: one JSON message per line.
function send(o) { process.stdout.write(JSON.stringify(o) + '\n'); }
async function handle(m) {
  if (m.id === undefined) return; // notifications need no reply
  try {
    if (m.method === 'initialize') {
      return send({ jsonrpc: '2.0', id: m.id, result: { protocolVersion: (m.params && m.params.protocolVersion) || '2024-11-05', capabilities: { tools: {} }, serverInfo: { name: 'workpaper', version: '0.1.0' } } });
    }
    if (m.method === 'tools/list') {
      return send({ jsonrpc: '2.0', id: m.id, result: { tools: Object.keys(tools).map(n => ({ name: n, description: tools[n].description, inputSchema: tools[n].input, annotations: { readOnlyHint: true } })) } });
    }
    if (m.method === 'tools/call') {
      const t = tools[m.params.name];
      if (!t) return send({ jsonrpc: '2.0', id: m.id, error: { code: -32602, message: 'Unknown tool' } });
      try {
        const out = await t.run(m.params.arguments || {});
        return send({ jsonrpc: '2.0', id: m.id, result: { content: [{ type: 'text', text: JSON.stringify(out, null, 2) }] } });
      } catch (e) {
        return send({ jsonrpc: '2.0', id: m.id, result: { isError: true, content: [{ type: 'text', text: e.message }] } });
      }
    }
    if (m.method === 'ping') return send({ jsonrpc: '2.0', id: m.id, result: {} });
    send({ jsonrpc: '2.0', id: m.id, error: { code: -32601, message: 'Method not found' } });
  } catch (e) { send({ jsonrpc: '2.0', id: m.id, error: { code: -32603, message: e.message } }); }
}

let buf = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', c => { buf += c; let i; while ((i = buf.indexOf('\n')) >= 0) { const l = buf.slice(0, i).trim(); buf = buf.slice(i + 1); if (l) { try { handle(JSON.parse(l)); } catch (e) {} } } });
