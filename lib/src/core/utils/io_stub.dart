// Stub file for dart:io on web - provides no-op implementations

class File {
  File(String path);
  
  void writeAsStringSync(String contents, {FileMode? mode, bool flush = false}) {}
  
  Future<void> writeAsBytes(List<int> bytes, {FileMode? mode, bool flush = false}) async {}
  
  Future<File> delete({bool recursive = false}) async => this;
  
  @override
  String toString() => 'File (stub)';
}

class Directory {
  Directory(String path);
  
  @override
  String toString() => 'Directory (stub)';
}

class FileSystemException implements Exception {
  final String message;
  FileSystemException(this.message);
  
  @override
  String toString() => message;
}

enum FileMode {
  read,
  write,
  append,
}

class IOSink {
  void write(Object? obj) {}
  void writeln(Object? obj) {}
  Future<void> close() => Future.value();
  Future<void> flush() => Future.value();
}
