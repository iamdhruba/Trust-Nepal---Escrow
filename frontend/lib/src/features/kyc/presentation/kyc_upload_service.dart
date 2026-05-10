import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/network/api_client.dart';

final kycUploadServiceProvider = Provider<KycUploadService>((ref) {
  return KycUploadService(ref.watch(apiClientProvider));
});

class KycUploadService {
  final ApiClient _api;
  final _picker = ImagePicker();

  KycUploadService(this._api);

  /// Pick a single image from camera or gallery and upload it.
  /// Returns the public URL on success.
  Future<String?> pickAndUpload(ImageSource source, String field) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return null;

    return uploadFile(picked, field);
  }

  Future<String?> uploadFile(XFile file, String field) async {
    final filename = file.name;

    try {
      MultipartFile multipartFile;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: filename,
        );
      } else {
        multipartFile = await MultipartFile.fromFile(
          file.path,
          filename: filename,
        );
      }

      // Create multipart form data
      final formData = FormData.fromMap({
        'file': multipartFile,
        'purpose': 'kyc',
      });

      // Upload directly to our backend
      final response = await _api.post(
        '/uploads/upload',
        data: formData,
      );

      if (response.data['success'] == true) {
        return response.data['data']['fileUrl'] as String;
      }
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }
}
