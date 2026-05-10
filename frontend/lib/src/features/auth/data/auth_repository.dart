import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<void> sendOTP(String phone) async {
    await _dio.post('/auth/otp/send', data: {'phone': phone});
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String phone,
    required String otp,
    required String deviceId,
    required String fingerprint,
  }) async {
    final response = await _dio.post('/auth/otp/verify', data: {
      'phone': phone,
      'otp': otp,
      'deviceId': deviceId,
      'fingerprint': fingerprint,
    });
    return response.data['data'];
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});
