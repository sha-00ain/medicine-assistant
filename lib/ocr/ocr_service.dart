/// Text read from a package photo.
class OcrResult {
  const OcrResult(this.text);

  final String text;
}

/// Thrown when the photo could not be processed at all (not when it simply
/// contains no readable text; that is an empty [OcrResult]).
class OcrFailure implements Exception {
  OcrFailure(this.message);

  final String message;

  @override
  String toString() => 'OcrFailure: $message';
}

/// Replaceable OCR layer. The real implementation lives in
/// platform_services.dart; tests use fakes.
abstract class OcrService {
  Future<OcrResult> recognize(String imagePath);
}

enum PhotoSource { camera, gallery }

/// Replaceable image source (camera or gallery).
abstract class ImageSourceService {
  /// Returns the image file path, or null if the user cancelled.
  Future<String?> pick(PhotoSource source);
}
