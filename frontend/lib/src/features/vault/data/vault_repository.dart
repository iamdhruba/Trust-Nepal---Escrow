import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class VaultRepository {
  final Dio _dio;

  VaultRepository(this._dio);

  Future<Map<String, dynamic>> createVault({
    required String title,
    required String description,
    required double amount,
    required String sellerPhone,
  }) async {
    final response = await _dio.post('/vaults', data: {
      'title': title,
      'description': description,
      'amount': amount,
      'sellerPhone': sellerPhone,
    });
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getVault(String id) async {
    final response = await _dio.get('/vaults/$id');
    return response.data['data'];
  }

  Future<List<dynamic>> listVaults() async {
    final response = await _dio.get('/vaults');
    return response.data['data'];
  }

  Future<void> transition(String id, String action, {Map<String, dynamic>? payload}) async {
    await _dio.post('/vaults/$id/$action', data: payload);
  }
}

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return VaultRepository(ref.read(dioProvider));
});
