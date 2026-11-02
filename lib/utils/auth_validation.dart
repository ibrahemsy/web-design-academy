/// Validates a new password and its confirmation before calling Supabase Auth.
bool isValidPasswordPair(String password, String confirmation) =>
    password.length >= 6 && password == confirmation;
