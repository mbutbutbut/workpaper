const handler = require('../api/team.js');
process.env.SUPABASE_URL = 'https://x.supabase.co'; process.env.SUPABASE_SECRET_KEY = 'sb_secret_test';
let users, members, failMemberInsert;
function reset() {
  users = [{ id: 'A1', email: 'admin@x.co' }, { id: 'J1', email: 'jeff@x.co' }, { id: 'B1', email: 'book@x.co' }];
  members = [{ user_id: 'A1', role: 'client' }, { user_id: 'J1', role: 'jeff' }, { user_id: 'B1', role: 'bookkeeper' }];
  failMemberInsert = false;
}
const tokens = { 'tok-admin': 'A1', 'tok-jeff': 'J1' };
const json = (status, body) => ({ ok: status < 300, status, text: async () => (body === undefined ? '' : JSON.stringify(body)), json: async () => body });
global.fetch = async (url, opts = {}) => {
  const u = new URL(url); const p = u.pathname; const q = u.searchParams; const m = opts.method || 'GET'; const body = opts.body ? JSON.parse(opts.body) : undefined;
  if (p === '/auth/v1/user') { const id = tokens[(opts.headers.Authorization || '').replace('Bearer ', '')]; return id ? json(200, { id }) : json(401, {}); }
  if (p === '/rest/v1/members') {
    if (m === 'GET') { let r = members; const uid = q.get('user_id'); const role = q.get('role'); if (uid) r = r.filter((x) => 'eq.' + x.user_id === uid); if (role) r = r.filter((x) => 'eq.' + x.role === role); return json(200, r.map((x) => ({ ...x }))); }
    if (m === 'POST') { if (failMemberInsert) return json(500, {}); members.push({ user_id: body.user_id, role: body.role }); return json(201); }
    if (m === 'PATCH') { const uid = q.get('user_id'); const hit = members.filter((x) => 'eq.' + x.user_id === uid); hit.forEach((x) => (x.role = body.role)); return json(200, hit); }
  }
  if (p === '/auth/v1/admin/users' && m === 'GET') return json(200, { users });
  if (p === '/auth/v1/admin/users' && m === 'POST') { if (users.some((x) => x.email === body.email)) return json(422, { msg: 'A user with this email address has already been registered' }); const id = 'N' + (users.length + 1); users.push({ id, email: body.email }); return json(200, { id, email: body.email }); }
  if (p.startsWith('/auth/v1/admin/users/') && m === 'PUT') return json(200, {});
  if (p.startsWith('/auth/v1/admin/users/') && m === 'DELETE') { const id = p.split('/').pop(); users = users.filter((x) => x.id !== id); members = members.filter((x) => x.user_id !== id); return json(200, {}); }
  return json(404, {});
};
async function call(method, token, body) {
  const res = { headers: {}, setHeader(k, v) { this.headers[k] = v; }, end(t) { this.body = JSON.parse(t); } };
  await handler({ method, headers: { authorization: token ? 'Bearer ' + token : '', 'x-apikey': 'pub' }, body }, res);
  return res;
}
let pass = 0, fail = 0;
function check(name, cond, extra) { if (cond) pass++; else { fail++; console.log('FAIL:', name, extra || ''); } }
(async () => {
  reset();
  let r = await call('GET', 'tok-admin', {}); check('GET refused', r.statusCode === 405);
  r = await call('POST', '', { action: 'list' }); check('no token 401', r.statusCode === 401);
  r = await call('POST', 'bad', { action: 'list' }); check('bad token 401', r.statusCode === 401);
  r = await call('POST', 'tok-jeff', { action: 'list' }); check('non-admin 403', r.statusCode === 403, JSON.stringify(r.body));
  r = await call('POST', 'tok-jeff', { action: 'remove', id: 'B1' }); check('non-admin cannot remove', r.statusCode === 403 && users.length === 3);
  r = await call('POST', 'tok-jeff', { action: 'add', email: 'z@x.co', password: 'longpassword1', role: 'client' }); check('non-admin cannot add', r.statusCode === 403 && users.length === 3);
  r = await call('POST', 'tok-admin', { action: 'list' }); check('list ok', r.statusCode === 200 && r.body.people.length === 3 && r.body.people.find((p) => p.you).email === 'admin@x.co', JSON.stringify(r.body));
  r = await call('POST', 'tok-admin', { action: 'add', email: 'new@x.co', password: 'short', role: 'jeff' }); check('short pw', r.statusCode === 400);
  r = await call('POST', 'tok-admin', { action: 'add', email: 'not-an-email', password: 'longpassword1', role: 'jeff' }); check('bad email', r.statusCode === 400);
  r = await call('POST', 'tok-admin', { action: 'add', email: 'new@x.co', password: 'longpassword1', role: 'root' }); check('bad role', r.statusCode === 400);
  r = await call('POST', 'tok-admin', { action: 'add', email: 'New@X.co', password: 'longpassword1', role: 'jeff' }); check('add ok', r.statusCode === 200 && users.some((u) => u.email === 'new@x.co') && members.some((m) => m.role === 'jeff' && m.user_id !== 'J1'), JSON.stringify(r.body));
  r = await call('POST', 'tok-admin', { action: 'add', email: 'new@x.co', password: 'longpassword1', role: 'jeff' }); check('duplicate 409', r.statusCode === 409, JSON.stringify(r.body));
  failMemberInsert = true; const before = users.length;
  r = await call('POST', 'tok-admin', { action: 'add', email: 'rollback@x.co', password: 'longpassword1', role: 'jeff' }); check('role failure rolls back user', r.statusCode === 502 && users.length === before, JSON.stringify(r.body)); failMemberInsert = false;
  r = await call('POST', 'tok-admin', { action: 'setRole', id: 'A1', role: 'jeff' }); check('cannot change own role', r.statusCode === 400);
  r = await call('POST', 'tok-admin', { action: 'setRole', id: 'B1', role: 'client' }); check('promote to admin', r.statusCode === 200 && members.find((m) => m.user_id === 'B1').role === 'client');
  r = await call('POST', 'tok-admin', { action: 'setRole', id: 'B1', role: 'bookkeeper' }); check('demote second admin ok', r.statusCode === 200);
  reset();
  r = await call('POST', 'tok-admin', { action: 'setRole', id: 'J1', role: 'bookkeeper' }); check('change jeff role', r.statusCode === 200 && members.find((m) => m.user_id === 'J1').role === 'bookkeeper');
  r = await call('POST', 'tok-admin', { action: 'resetPassword', id: 'J1', password: 'short' }); check('reset short refused', r.statusCode === 400);
  r = await call('POST', 'tok-admin', { action: 'resetPassword', id: 'J1', password: 'a-good-new-password' }); check('reset ok', r.statusCode === 200);
  r = await call('POST', 'tok-admin', { action: 'remove', id: 'A1' }); check('cannot remove self', r.statusCode === 400 && users.some((u) => u.id === 'A1'));
  r = await call('POST', 'tok-admin', { action: 'remove', id: 'J1' }); check('remove ok', r.statusCode === 200 && !users.some((u) => u.id === 'J1') && !members.some((m) => m.user_id === 'J1'));
  r = await call('POST', 'tok-admin', { action: 'setRole', id: 'B1', role: 'client' }); r = await call('POST', 'tok-admin', { action: 'remove', id: 'A1' }); check('still cannot remove self even with two admins', r.statusCode === 400);
  r = await call('POST', 'tok-admin', { action: 'nope' }); check('unknown action', r.statusCode === 400);
  delete process.env.SUPABASE_SECRET_KEY; r = await call('POST', 'tok-admin', { action: 'list' }); check('missing key 500 with help', r.statusCode === 500 && /secret key/i.test(r.body.error));
  console.log(pass + ' passed, ' + fail + ' failed'); if (fail) process.exit(1);
})();
