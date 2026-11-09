// Copyright (c) 2026 Ibrahim Zainab. All rights reserved.
// GitHub: https://github.com/ibrahemsy

/// Small, deterministic formatting helpers shared by reports and certificates.
String csvCell(Object? value) =>
    '"${(value?.toString() ?? '').replaceAll('"', '""')}"';

String htmlEscapeText(Object? value) {
  return (value?.toString() ?? '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
