import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

class VaultStateModel {
  final bool isLoading;
  final List<dynamic> vaults;
  final String? error;
  
  const VaultStateModel({
    this.isLoading = false,
    this.vaults = const [],
    this.error,
  });

  double get totalLocked {
    return vaults
        .where((v) => ['FUNDED', 'SHIPPED', 'DELIVERED'].contains(v['state']))
        .fold(0.0, (sum, v) => sum + (v['amount'] as num).toDouble());
  }

  VaultStateModel copyWith({bool? isLoading, List<dynamic>? vaults, String? error}) {
    return VaultStateModel(
      isLoading: isLoading ?? this.isLoading,
      vaults: vaults ?? this.vaults,
      error: error,
    );
  }
}

final vaultViewModelProvider = StateNotifierProvider<VaultViewModel, VaultStateModel>(
  (ref) => VaultViewModel(ref.watch(apiClientProvider)),
);

class VaultViewModel extends StateNotifier<VaultStateModel> {
  final ApiClient _api;

  VaultViewModel(this._api) : super(const VaultStateModel()) {
    fetchVaults();
  }

  Future<void> fetchVaults() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.get('/vaults');
      state = state.copyWith(isLoading: false, vaults: res.data['data']);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Failed to fetch vaults';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Map<String, dynamic>?> createVaultWithResponse(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.post('/vaults', data: data);
      await fetchVaults();
      return res.data['data'];
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Failed to create vault';
      state = state.copyWith(isLoading: false, error: msg);
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchVaultDetails(String id) async {
    try {
      final res = await _api.get('/vaults/$id');
      return res.data['data'];
    } catch (e) {
      return null;
    }
  }

  Future<bool> transitionVault(String id, String action, [Map<String, dynamic> payload = const {}]) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post('/vaults/$id/$action', data: payload);
      await fetchVaults();
      return true;
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Action failed';
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>?> lookupUser(String phone) async {
    try {
      final res = await _api.get('/users/lookup/$phone');
      return res.data['data'];
    } catch (_) {
      return null;
    }
  }
}
