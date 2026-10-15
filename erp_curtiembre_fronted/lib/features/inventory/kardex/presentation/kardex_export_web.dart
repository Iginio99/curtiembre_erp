import 'dart:js_interop';

import 'package:web/web.dart' as web;

void downloadKardexCsv(String csv, String filename) {
  final blob = web.Blob(
    <JSAny>[csv.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  Future<void>.delayed(
    const Duration(seconds: 30),
  ).then((_) => web.URL.revokeObjectURL(url));
}
