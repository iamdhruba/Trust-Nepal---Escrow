import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class KYCRepository {
  final Dio _dio;

  KYCRepository(this._dio);

  Future<void> submitKYC({
    required String fullName,
    required DateTime dob,
    required String idType,
    required String idNumber,
    required String address,
    required String idFrontPath,
    required String idBackPath,
    required String selfiePath,
  }) async {
    final formData = FormData.fromMap({
      'fullName': fullName,
      'dob': dob.toIso8601String(),
      'idType': idType,
      'idNumber': idNumber,
      'address': address,
      'idFront': await MultipartFile.fromFile(idFrontPath),
      'idBack': await MultipartFile.fromFile(idBackPath),
      'selfie': await MultipartFile.fromFile(selfiePath),
    });

    await _dio.post('/kyc/submit', data: formData);
  }

  Future<Map<String, dynamic>> getKYCStatus() async {
    final response = await _dio.get('/kyc/status');
    return response.data['data'];
  }
}

final kycRepositoryProvider = Provider<KYCRepository>((ref) {
  return KYCRepository(ref.read(dioProvider));
});
