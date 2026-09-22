// Team management for Workpaper. Runs on Vercel, not in the browser: it holds the Supabase
// secret key, and it only acts for a signed-in admin (a member whose role is "client").
//
// Needs two environment variables in Vercel:
//   SUPABASE_URL          the project URL, e.g. https://xxxx.supabase.co
//   SUPABASE_SECRET_KEY   the project's secret key (or SUPABASE_SERVICE_ROLE_KEY)
// The browser sends its own sign-in token; this file never trusts anything else about the caller.

const ROLES = ['client', 'bookkeeper', 'jeff']; // shown as Admin, Bookkeeper, Team member
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const enc = encodeURIComponent;

function config() {
  return {
    url: (process.env.SUPABASE_URL || '').replace(/\/$/, ''),
    key: process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || ''
  };
}

function send(res, status, body) {
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Cache-Control', 'no-store');
  res.end(JSON.stringify(body));
}

async function sb(cfg, path, method, body, extra) {
  const headers = Object.assign({ apikey: cfg.key, 'Content-Type': 'application/json' }, extra || {});
  if (cfg.key.startsWith('eyJ')) headers.Authorization = 'Bearer ' + cfg.key; // legacy JWT-style key
  const res = await fetch(cfg.url + path, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
  const text = await res.text();
  let data = null;
  try { data = text ? JSON.parse(text) : null; } catch (e) { data = text; }
  return { ok: res.ok, status: res.status, data };
}

async function admins(cfg) {
  const r = await sb(cfg, '/rest/v1/members?role=eq.client&select=user_id', 'GET');
  return r.ok && Array.isArray(r.data) ? r.data.map((m) => m.user_id) : null;
}

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') return send(res, 405, { error: 'Use POST.' });
  const cfg = config();
  if (!cfg.url || !cfg.key) return send(res, 500, { error: 'The team service is not set up yet. Add the Supabase secret key in Vercel (see SETUP.md).' });

  // 1. Who is calling? Ask Supabase to check their sign-in token.
  const token = String(req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  const publicKey = String(req.headers['x-apikey'] || '');
  if (!token) return send(res, 401, { error: 'Sign in again.' });
  let caller;
  try {
    const who = await fetch(cfg.url + '/auth/v1/user', { headers: { apikey: publicKey, Authorization: 'Bearer ' + token } });
    if (!who.ok) return send(res, 401, { error: 'Sign in again.' });
    caller = await who.json();
  } catch (e) { return send(res, 502, { error: 'Could not reach the sign-in service.' }); }

  // 2. Are they an admin?
  const mine = await sb(cfg, '/rest/v1/members?user_id=eq.' + enc(caller.id) + '&select=role', 'GET');
  if (!mine.ok || !Array.isArray(mine.data) || !mine.data[0] || mine.data[0].role !== 'client') {
    return send(res, 403, { error: 'Only an admin can manage the team.' });
  }

  let input = req.body;
  if (typeof input === 'string') { try { input = JSON.parse(input); } catch (e) { input = {}; } }
  input = input || {};
  const action = input.action;

  try {
    if (action === 'list') {
      const [u, m] = await Promise.all([
        sb(cfg, '/auth/v1/admin/users?per_page=200', 'GET'),
        sb(cfg, '/rest/v1/members?select=user_id,role,first_name,last_name', 'GET')
      ]);
      if (!u.ok || !m.ok) return send(res, 502, { error: 'Could not load the team.' });
      const rows = {};
      m.data.forEach((x) => { rows[x.user_id] = x; });
      const people = (u.data.users || []).map((x) => {
        const row = rows[x.id] || {};
        return { id: x.id, email: x.email, role: row.role || null, firstName: row.first_name || '', lastName: row.last_name || '', lastSignIn: x.last_sign_in_at || null, you: x.id === caller.id };
      });
      people.sort((a, b) => String(a.email).localeCompare(String(b.email)));
      return send(res, 200, { people });
    }

    if (action === 'add') {
      const email = String(input.email || '').trim().toLowerCase();
      const password = String(input.password || '');
      const firstName = String(input.firstName || '').trim();
      const lastName = String(input.lastName || '').trim();
      if (!EMAIL.test(email)) return send(res, 400, { error: 'Enter a valid email address.' });
      if (ROLES.indexOf(input.role) < 0) return send(res, 400, { error: 'Choose a role.' });
      if (password.length < 10) return send(res, 400, { error: 'The first password needs at least 10 characters.' });
      if (!firstName || !lastName) return send(res, 400, { error: 'Enter a first and last name.' });
      const created = await sb(cfg, '/auth/v1/admin/users', 'POST', { email, password, email_confirm: true });
      if (!created.ok) {
        const taken = created.status === 422 || /already|registered|exists/i.test(JSON.stringify(created.data || ''));
        return send(res, taken ? 409 : 502, { error: taken ? 'That email already has an account.' : 'Could not create the account.' });
      }
      const row = await sb(cfg, '/rest/v1/members', 'POST', { user_id: created.data.id, role: input.role, first_name: firstName, last_name: lastName }, { Prefer: 'return=minimal' });
      if (!row.ok) {
        await sb(cfg, '/auth/v1/admin/users/' + enc(created.data.id), 'DELETE');
        return send(res, 502, { error: 'Could not set the role, so nothing was created.' });
      }
      return send(res, 200, { ok: true, id: created.data.id });
    }

    const id = String(input.id || '');
    if (!id) return send(res, 400, { error: 'Choose a person.' });

    if (action === 'setRole') {
      if (ROLES.indexOf(input.role) < 0) return send(res, 400, { error: 'Choose a role.' });
      if (id === caller.id) return send(res, 400, { error: 'You cannot change your own role.' });
      const a = await admins(cfg);
      if (!a) return send(res, 502, { error: 'Could not check the admins.' });
      if (a.indexOf(id) > -1 && input.role !== 'client' && a.length <= 1) return send(res, 400, { error: 'There must always be at least one admin.' });
      const r = await sb(cfg, '/rest/v1/members?user_id=eq.' + enc(id), 'PATCH', { role: input.role }, { Prefer: 'return=representation' });
      if (!r.ok) return send(res, 502, { error: 'Could not change the role.' });
      if (Array.isArray(r.data) && r.data.length === 0) {
        const ins = await sb(cfg, '/rest/v1/members', 'POST', { user_id: id, role: input.role }, { Prefer: 'return=minimal' });
        if (!ins.ok) return send(res, 502, { error: 'Could not set the role.' });
      }
      return send(res, 200, { ok: true });
    }

    if (action === 'setName') {
      const firstName = String(input.firstName || '').trim();
      const lastName = String(input.lastName || '').trim();
      if (!firstName || !lastName) return send(res, 400, { error: 'Enter a first and last name.' });
      const r = await sb(cfg, '/rest/v1/members?user_id=eq.' + enc(id), 'PATCH', { first_name: firstName, last_name: lastName }, { Prefer: 'return=minimal' });
      if (!r.ok) return send(res, 502, { error: 'Could not change the name.' });
      return send(res, 200, { ok: true });
    }

    if (action === 'resetPassword') {
      const password = String(input.password || '');
      if (password.length < 10) return send(res, 400, { error: 'The new password needs at least 10 characters.' });
      const r = await sb(cfg, '/auth/v1/admin/users/' + enc(id), 'PUT', { password });
      if (!r.ok) return send(res, 502, { error: 'Could not reset the password.' });
      return send(res, 200, { ok: true });
    }

    if (action === 'remove') {
      if (id === caller.id) return send(res, 400, { error: 'You cannot remove yourself.' });
      const a = await admins(cfg);
      if (!a) return send(res, 502, { error: 'Could not check the admins.' });
      if (a.indexOf(id) > -1 && a.length <= 1) return send(res, 400, { error: 'There must always be at least one admin.' });
      const r = await sb(cfg, '/auth/v1/admin/users/' + enc(id), 'DELETE');
      if (!r.ok) return send(res, 502, { error: 'Could not remove that person.' });
      return send(res, 200, { ok: true });
    }

    return send(res, 400, { error: 'Unknown request.' });
  } catch (e) {
    return send(res, 500, { error: 'Something went wrong. Try again.' });
  }
};
