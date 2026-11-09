// Copyright (c) 2026 Ibrahim Zainab. All rights reserved.
// GitHub: https://github.com/ibrahemsy

/// Validates a new password and its confirmation before calling Supabase Auth.
bool isValidPasswordPair(String password, String confirmation) =>
    password.length >= 6 && password == confirmation;

/// Builds a clean auth callback URL while preserving the app's deployment path.
/// Query parameters and fragments are deliberately excluded from the callback.
String buildAcademyRedirectUrl(Uri current) => Uri(
  scheme: current.scheme,
  host: current.host,
  port: current.hasPort ? current.port : null,
  path: current.path,
).toString();
