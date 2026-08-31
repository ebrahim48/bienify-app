/// A best-effort content type for an upload, from its file extension.
///
/// Good enough for what this app ever hands the picker back: a JPEG or PNG
/// from the camera or the gallery. Anything else falls back to a generic
/// binary type rather than guessing.
String contentTypeForPath(String path) {
  final dot = path.lastIndexOf('.');
  final ext = dot == -1 ? '' : path.substring(dot + 1).toLowerCase();
  return switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'heic' => 'image/heic',
    'webp' => 'image/webp',
    'pdf' => 'application/pdf',
    _ => 'application/octet-stream',
  };
}
