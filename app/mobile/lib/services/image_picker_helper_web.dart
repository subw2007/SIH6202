import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import '../providers/report_form_provider.dart';

Future<Uint8List?> pickImageBytes(ImagePickSource source) {
  final completer = Completer<Uint8List?>();
  final input = html.FileUploadInputElement()..accept = 'image/*';

  if (source == ImagePickSource.camera) {
    input.setAttribute('capture', 'environment');
  }

  input.click();

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.listen((_) {
      if (reader.result != null) {
        completer.complete(reader.result as Uint8List);
      } else {
        completer.complete(null);
      }
    });
    reader.onError.listen((_) {
      completer.complete(null);
    });
  });

  return completer.future;
}
