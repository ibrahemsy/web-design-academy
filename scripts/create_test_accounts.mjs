#!/usr/bin/env node
// Copyright (c) 2026 Ibrahim Zainab. All rights reserved.
// GitHub: https://github.com/ibrahemsy

/**
 * Create isolated test users in Supabase Auth.
 * The service-role secret stays in this local process and is never written.
 * Role changes are emitted as SQL for the project owner to run in SQL Editor:
 * the profile role guard intentionally rejects service_role REST updates.
 */
import { randomBytes } from 'node:crypto';
import { access, chmod, unlink, writeFile } from 'node:fs/promises';

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
  throw new Error('Safety stop: restricted to the approved test project. Check URL and ALLOW_TEST_ACCOUNTS_ON_PROJECT.');
}

const credentialsPath = new URL('../test-accounts.generated.json', import.meta.url);
const rolesPath = new URL('../test-accounts-roles.generated.sql', import.meta.url);
for (const path of [credentialsPath, rolesPath]) {
  try {
    await access(path);
    throw new Error(`${path.pathname} already exists. Move it securely before rerunning; outputs are never overwritten.`);
  } catch (error) {
    if (error?.code !== 'ENOENT') throw error;
  }
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
    const message = typeof data === 'object'
      ? (data.msg || data.message || data.error_description || data.error)
      : data;
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
let credentialsWritten = false;

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
    if (!userId || !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(userId)) {
      throw new Error(`Supabase returned an invalid user ID for ${account.email}`);
    }
    createdIds.push(userId);
    credentials.push({
      email: account.email,
      password,
      role: account.role,
      user_id: userId,
    });
    console.log(`CREATED ${account.email}; pending role assignment: ${account.role}`);
  }

  if (credentials.length) {
    const payload = {
      warning: 'LOCAL TEST CREDENTIALS. Never commit, upload, or share this file.',
      project_ref: projectRef,
      accounts: credentials,
    };
    await writeFile(credentialsPath, `${JSON.stringify(payload, null, 2)}\n`, { mode: 0o600, flag: 'wx' });
    credentialsWritten = true;
    await chmod(credentialsPath, 0o600);

    const roleUpdates = credentials
      .filter(account => account.role !== 'student')
      .map(account => `update public.profiles set role = '${account.role}' where id = '${account.user_id}';`);
    const sql = [
      '-- Review the UUIDs and run this in Supabase SQL Editor for the test project only.',
      '-- The trigger permits owner-run SQL Editor role bootstrap; REST service_role updates are intentionally blocked.',
      ...roleUpdates,
      '',
    ].join('\n');
    await writeFile(rolesPath, sql, { mode: 0o600, flag: 'wx' });
    await chmod(rolesPath, 0o600);
    console.log(`Credentials saved locally: ${credentialsPath.pathname}`);
    console.log(`Owner-only role SQL saved locally: ${rolesPath.pathname}`);
    console.log('Next: review and run test-accounts-roles.generated.sql in the Supabase SQL Editor.');
  } else {
    console.log('No new accounts were created. Existing passwords are intentionally not recoverable.');
  }
} catch (error) {
  if (credentialsWritten) {
    try { await unlink(credentialsPath); } catch {}
  }
  try { await unlink(rolesPath); } catch {}
  for (const id of createdIds.reverse()) {
    try {
      await request(`/auth/v1/admin/users/${encodeURIComponent(id)}`, { method: 'DELETE' });
    } catch {
      console.error(`WARNING: cleanup failed for newly created user ID ${id}; remove it in Supabase Auth > Users.`);
    }
  }
  throw error;
}
