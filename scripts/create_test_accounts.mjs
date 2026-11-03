#!/usr/bin/env node
/**
 * Creates isolated test users for Web Design Academy.
 *
 * Required environment:
 *   SUPABASE_URL=https://<project-ref>.supabase.co
 *   SUPABASE_SERVICE_ROLE_KEY=<server-side secret; never commit/share>
 *   ALLOW_TEST_ACCOUNTS_ON_PROJECT=<same project ref as SUPABASE_URL>
 *
 * This uses only Node.js built-ins. New accounts are email-confirmed because
 * example.com is a reserved testing domain and cannot receive mail.
 */
import { randomBytes } from 'node:crypto';
import { chmod, writeFile } from 'node:fs/promises';

const EXPECTED_PROJECT_REF = 'dgeohwxzleznygmfjfdq';
const url = process.env.SUPABASE_URL?.replace(/\/$/, '');
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
const allowRef = process.env.ALLOW_TEST_ACCOUNTS_ON_PROJECT;

if (!url || !serviceKey) {
  throw new Error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in your local shell.');
}
const parsed = new URL(url);
const projectRef = parsed.hostname.split('.')[0];
if (parsed.protocol !== 'https:' || projectRef !== EXPECTED_PROJECT_REF ||
    allowRef !== EXPECTED_PROJECT_REF) {
  throw new Error('Safety stop: this script is restricted to the explicitly approved test project. Check URL and ALLOW_TEST_ACCOUNTS_ON_PROJECT.');
}

const headers = {
  apikey: serviceKey,
  Authorization: `Bearer ${serviceKey}`,
  'Content-Type': 'application/json',
};

async function request(path, options = {}) {
  const response = await fetch(`${url}${path}`, {
    ...options,
    headers: { ...headers, ...(options.headers ?? {}) },
  });
  const body = await response.text();
  let data;
  try { data = body ? JSON.parse(body) : null; } catch { data = body; }
  if (!response.ok) {
    const message = typeof data === 'object' ? (data.msg || data.message || data.error_description || data.error) : data;
    throw new Error(`Supabase request failed (${response.status}): ${message || 'unknown error'}`);
  }
  return data;
}

const definitions = [
  { email: 'academy.admin@example.com', displayName: 'Demo Academy Administrator', role: 'admin' },
  { email: 'academy.teacher@example.com', displayName: 'Demo Academy Teacher', role: 'teacher' },
  { email: 'academy.student@example.com', displayName: 'Demo Academy Student', role: 'student' },
];

const listed = await request('/auth/v1/admin/users?page=1&per_page=1000');
const existingUsers = listed?.users ?? [];
const credentials = [];
const createdIds = [];

try {
  for (const account of definitions) {
    const existing = existingUsers.find(user => user.email?.toLowerCase() === account.email);
    if (existing) {
      console.log(`SKIP ${account.email}: account already exists; password and role were not changed.`);
      continue;
    }

    const password = `WdA!9${randomBytes(24).toString('base64url')}z`;
    const created = await request('/auth/v1/admin/users', {
      method: 'POST',
      body: JSON.stringify({
        email: account.email,
        password,
        email_confirm: true,
        user_metadata: { display_name: account.displayName },
      }),
    });
    const userId = created?.id ?? created?.user?.id;
    if (!userId) throw new Error(`Supabase did not return a user ID for ${account.email}`);
    createdIds.push(userId);

    const profile = await request(
      `/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}`,
      {
        method: 'PATCH',
        headers: { Prefer: 'return=representation' },
        body: JSON.stringify({ display_name: account.displayName, role: account.role }),
      },
    );
    if (!Array.isArray(profile) || profile.length !== 1) {
      throw new Error(`Profile role update did not affect exactly one row for ${account.email}`);
    }

    credentials.push({
      email: account.email,
      password,
      role: account.role,
      user_id: userId,
    });
    console.log(`CREATED ${account.email} (${account.role})`);
  }
} catch (error) {
  // Roll back only users created by this run; never touch pre-existing accounts.
  for (const id of createdIds.reverse()) {
    try { await request(`/auth/v1/admin/users/${encodeURIComponent(id)}`, { method: 'DELETE' }); }
    catch { console.error(`WARNING: automatic cleanup failed for newly created user ID ${id}; remove it in Supabase Auth > Users.`); }
  }
  throw error;
}

if (credentials.length) {
  const output = new URL('../test-accounts.generated.json', import.meta.url);
  await writeFile(output, `${JSON.stringify({
    warning: 'LOCAL TEST CREDENTIALS. Never commit, upload, or share this file.',
    project_ref: projectRef,
    accounts: credentials,
  }, null, 2)}\n`, { mode: 0o600, flag: 'wx' });
  await chmod(output, 0o600);
  console.log(`Saved credentials for newly created users to ${output.pathname}`);
} else {
  console.log('No new accounts were created. Existing account passwords are intentionally not recoverable.');
}
