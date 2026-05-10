import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class KycState {
  final bool isLoading;
  final String? error;
  final bool isSubmitted;

  const KycState({
    this.isLoading = false,
    this.error,
    this.isSubmitted = false,
  });

  KycState copyWith({bool? isLoading, String? error, bool? isSubmitted}) {
    return KycState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }
}

final kycViewModelProvider = StateNotifierProvider<KycViewModel, KycState>(
  (ref) => KycViewModel(ref.watch(apiClientProvider)),
);

class KycViewModel extends StateNotifier<KycState> {
  final ApiClient _api;

  KycViewModel(this._api) : super(const KycState());

  Future<void> submitKyc({
    required String fullName,
    required String dob,
    required String idType,
    required String idNumber,
    required String frontUrl,
    required String backUrl,
    required String selfieUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.post('/kycs', data: {
        'fullName': fullName,
        'dob': dob,
        'idType': idType,
        'idNumber': idNumber,
        'documents': {
          'frontUrl': frontUrl,
          'backUrl': backUrl,
          'selfieUrl': selfieUrl,
        }
      });
      state = state.copyWith(isLoading: false, isSubmitted: true);
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Failed to submit KYC';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
