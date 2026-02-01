import 'dart:io';
import 'package:flutter/material.dart';

Widget fileImageWidget({
  required String path,
  required BoxFit fit,
  required Widget placeholder,
  required Widget errorWidget,
}) {
  final file = File(path);
  if (!file.existsSync()) return errorWidget;
  return Image.file(
    file,
    fit: fit,
    errorBuilder: (_, __, ___) => errorWidget,
  );
}
