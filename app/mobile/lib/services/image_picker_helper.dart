import 'dart:typed_data';
import '../providers/report_form_provider.dart';

import 'image_picker_helper_stub.dart'
    if (dart.library.html) 'image_picker_helper_web.dart' as impl;

Future<Uint8List?> selectImage(ImagePickSource source) {
  return impl.pickImageBytes(source);
}
