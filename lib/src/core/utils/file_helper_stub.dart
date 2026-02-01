// Stub for file_helper compatibility with web platform
// This file provides a no-op implementation for web builds
class PlatformFile {
  final String? path;
  final String? name;
  final String? bytes;
  final int? size;
  
  PlatformFile({
    this.path,
    this.name,
    this.bytes,
    this.size,
  });
}

PlatformFile createPlatformFile(String path) {
  return PlatformFile(path: path);
}
