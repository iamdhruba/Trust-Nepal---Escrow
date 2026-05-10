import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PaymentState {
  final bool isLoading;
  final String? error;
  final String? checkoutUrl;

  const PaymentState({
    this.isLoading = false,
    this.error,
    this.checkoutUrl,
  });

  PaymentState copyWith({bool? isLoading, String? error, String? checkoutUrl}) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      checkoutUrl: checkoutUrl,
    );
  }
}

final paymentViewModelProvider = StateNotifierProvider<PaymentViewModel, PaymentState>(
  (ref) => PaymentViewModel(ref.watch(apiClientProvider)),
);

class PaymentViewModel extends StateNotifier<PaymentState> {
  final ApiClient _api;

  PaymentViewModel(this._api) : super(const PaymentState());

  Future<void> initiatePayment(String vaultId, String psp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.post('/payment/initiate', data: {
        'vaultId': vaultId,
        'psp': psp,
      });
      
      final data = res.data['data'];
      final checkoutUrl = data['checkoutUrl'] ?? data['url'];

      if (checkoutUrl != null) {
        state = state.copyWith(isLoading: false);
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          state = state.copyWith(error: 'Could not launch payment gateway');
        }
      } else {
        state = state.copyWith(isLoading: false, error: 'Payment gateway URL not found');
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Failed to initiate payment';
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> verifyPayment(String pidx) async {
    state = state.copyWith(isLoading: true);
    try {
      await _api.get('/payments/esewa/callback', queryParameters: {'data': pidx});
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Verification failed');
    }
  }
}
