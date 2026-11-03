import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool> printHtmlDocument(String html) async {
  final printWindow = web.window.open('', '_blank');
  if (printWindow == null) return false;
  printWindow.document.write(html.toJS);
  printWindow.document.close();
  printWindow.focus();
  printWindow.print();
  return true;
}

Future<bool> downloadCsv(String filename, String csv) async {
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = 'data:text/csv;charset=utf-8,${Uri.encodeComponent('\uFEFF$csv')}';
  anchor.download = filename;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  return true;
}
