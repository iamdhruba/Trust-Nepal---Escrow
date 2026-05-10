import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.nepaltrust.com.np/api/v1', // Production URL
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Certificate Pinning (Requirement: hhh.md line 175)
  // SHA-256 Fingerprint of the leaf certificate
  const String primaryFingerprint = "70 51 70 51 ..."; // Placeholder
  
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // In production, we compare the certificate fingerprint
      // return validateFingerprint(cert, primaryFingerprint);
      return false; // Reject all bad certificates by default
    };
    return client;
  };

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'nt.access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (DioException e, handler) async {
      if (e.response?.statusCode == 401) {
        // TODO: Implement token refresh rotation (Sprint 1)
      }
      return handler.next(e);
    },
  ));

  return dio;
});
