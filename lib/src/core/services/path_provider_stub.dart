// Stub for path_provider on web
Future<Directory> getTemporaryDirectory() async {
  throw UnsupportedError('getTemporaryDirectory is not supported on web');
}

class Directory {
  final String path;
  Directory(this.path);
}




