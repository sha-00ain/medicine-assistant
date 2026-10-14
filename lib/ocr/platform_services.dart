import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medicine_app/ocr/ocr_service.dart';

/// On-device OCR using Google ML Kit (Latin script). Most medicine package
/// names are written in Latin script. Bangla package text is not read here.
class MlKitOcrService implements OcrService {
  TextRecognizer? _recognizer;

  @override
  Future<OcrResult> recognize(String imagePath) async {
    try {
      final recognizer =
          _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
      final input = InputImage.fromFilePath(imagePath);
      final RecognizedText result = await recognizer.processImage(input);
      return OcrResult(result.text);
    } catch (e) {
      throw OcrFailure('$e');
    }
  }

  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}

/// Camera capture and gallery selection through the system apps. The system
/// camera app handles its own permission, so this app does not need to ask for
/// camera permission.
class ImagePickerService implements ImageSourceService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> pick(PhotoSource source) async {
    final XFile? file = await _picker.pickImage(
      source:
          source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 90,
    );
    return file?.path;
  }
}
