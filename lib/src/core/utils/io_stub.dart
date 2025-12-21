class File {
  final String path;
  File(this.path);

  Future<File> create({bool recursive = false}) async => this;
  Future<void> writeAsBytes(List<int> bytes) async {}
  // Accepts optional mode to mirror dart:io signature; ignored in stub
  void writeAsStringSync(String data, {FileMode mode = FileMode.write, bool flush = false}) {}
  Future<void> delete() async {}
}

class FileMode {
  static const write = FileMode._();
  static const append = FileMode._();
  const FileMode._();
}

