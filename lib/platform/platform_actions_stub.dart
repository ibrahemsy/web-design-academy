// Copyright (c) 2026 Ibrahim Zainab. All rights reserved.
// GitHub: https://github.com/ibrahemsy

import 'package:flutter/services.dart';

Future<bool> printHtmlDocument(String html) async {
  final text = html
      .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  await Clipboard.setData(ClipboardData(text: text));
  return false;
}

Future<bool> downloadCsv(String filename, String csv) async {
  await Clipboard.setData(ClipboardData(text: '\uFEFF$csv'));
  return false;
}
