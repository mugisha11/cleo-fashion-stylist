// Stub file for non-web platforms
// This file provides empty implementations of html classes used on web

class Blob {
  Blob(List<int> data, String type);
}

class Url {
  static String createObjectUrlFromBlob(Blob blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  AnchorElement({String? href});
  void setAttribute(String name, String value) {}
  void click() {}
}
