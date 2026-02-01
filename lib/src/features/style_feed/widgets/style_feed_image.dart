import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'style_feed_image_stub.dart'
    if (dart.library.io) 'style_feed_image_io.dart' as file_image_impl;

/// Displays a post image from [imagePath]: file path, http(s) URL, or data URL.
class StyleFeedImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const StyleFeedImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('data:')) {
      return _DataUrlImage(
        dataUrl: imagePath,
        fit: fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    }
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: fit,
        placeholder: (_, __) => placeholder ?? _shimmer(),
        errorWidget: (_, __, ___) => errorWidget ?? _error(),
      );
    }
    return _FileImage(
      path: imagePath,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }

  static Widget _shimmer() => Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image_outlined, size: 48)),
      );

  static Widget _error() => Container(
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
      );
}

class _DataUrlImage extends StatelessWidget {
  final String dataUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const _DataUrlImage({
    required this.dataUrl,
    required this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final base64 = dataUrl.contains(',') ? dataUrl.split(',').last : dataUrl;
    try {
      final bytes = base64Decode(base64);
      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            errorWidget ?? StyleFeedImage._error(),
      );
    } catch (_) {
      return errorWidget ?? StyleFeedImage._error();
    }
  }
}

class _FileImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const _FileImage({
    required this.path,
    required this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return _FileImageImpl(
      path: path,
      fit: fit,
      placeholder: placeholder ?? StyleFeedImage._shimmer(),
      errorWidget: errorWidget ?? StyleFeedImage._error(),
    );
  }
}

class _FileImageImpl extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final Widget placeholder;
  final Widget errorWidget;

  const _FileImageImpl({
    required this.path,
    required this.fit,
    required this.placeholder,
    required this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return file_image_impl.fileImageWidget(
      path: path,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
