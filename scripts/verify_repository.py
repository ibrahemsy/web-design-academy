#!/usr/bin/env python3
"""Repository release invariants for Web Design Academy.

This is a static guardrail; it does not replace applying migrations or running
security_smoke_test.sql against the target Supabase project.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
MIGRATIONS = ROOT / "supabase" / "migrations"
TEST_SQL = ROOT / "supabase" / "tests" / "security_smoke_test.sql"

def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)

files = sorted(MIGRATIONS.glob("*.sql"))
if not files:
    fail("No Supabase migration files found")

versions = []
for path in files:
    match = re.match(r"^(\d{4})_.+\.sql$", path.name)
    if not match:
        fail(f"Migration filename must start with a four-digit version: {path.name}")
    versions.append(int(match.group(1)))

if len(versions) != len(set(versions)):
    fail("Duplicate migration version detected")
expected = list(range(1, max(versions) + 1))
if versions != expected:
    fail(f"Migration sequence has a gap or is out of order: found {versions}")

latest = MIGRATIONS / "0025_increase_certificate_code_entropy.sql"
if not latest.exists():
    fail("Latest certificate entropy migration is missing")

latest_sql = latest.read_text(encoding="utf-8")
private_access_migration = MIGRATIONS / "0026_revoke_direct_private_certificate_report_access.sql"
if not private_access_migration.exists():
    fail("Private certificate report access migration 0026 is missing")
private_access_sql = private_access_migration.read_text(encoding="utf-8")
if "revoke all on function private.get_course_certificate_report(uuid)" not in private_access_sql.lower():
    fail("Migration 0026 must revoke direct access to the private certificate report RPC")
verifier_migration = MIGRATIONS / "0027_restrict_direct_private_certificate_verification.sql"
if not verifier_migration.exists():
    fail("Private certificate verification migration 0027 is missing")
verifier_sql = verifier_migration.read_text(encoding="utf-8")
if "revoke all on function private.verify_course_certificate(text)" not in private_access_sql.lower():
    fail("Migration 0027 must revoke direct access to the private certificate verifier")
required_fragments = (
    "security definer",
    "set search_path = ''",
    "pg_catalog.gen_random_uuid()",
    "substr(replace(pg_catalog.gen_random_uuid()::text, '-', ''), 1, 32)",
)
for fragment in required_fragments:
    if fragment not in latest_sql:
        fail(f"Certificate issuance migration is missing required invariant: {fragment}")

if not TEST_SQL.exists():
    fail("Supabase security smoke test is missing")
smoke = TEST_SQL.read_text(encoding="utf-8")
for fragment in (
    "relrowsecurity",
    "has_table_privilege",
    "has_function_privilege",
    "public.issue_course_certificate(uuid)",
    "public.get_my_course_certificates()",
    "public.verify_course_certificate(text)",
    "public.get_course_certificate_report(uuid)",
    "private.get_course_certificate_report(uuid)",
    "private.verify_course_certificate(text)",
    "SECURITY DEFINER",
    "pg_catalog.gen_random_uuid()",
    "storage.buckets",
    "course-videos",
    "eligible users read course videos",
):
    if fragment not in smoke:
        fail(f"Security smoke test is missing assertion: {fragment}")

print(f"PASS: {len(files)} migrations are sequential (0001-{max(versions):04d}).")
print("PASS: certificate issuance uses the expected UUIDv4 generator and hardened search_path.")
print("PASS: Supabase certificate security smoke test covers RLS, grants, RPC roles, private implementation isolation, and code generation.")
print("NOTE: These checks are static. Run security_smoke_test.sql on the target Supabase database before launch.")
