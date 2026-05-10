import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Added for kIsWeb and defaultTargetPlatform
import '../../../core/network/api_client.dart';
import 'dart:io' show HttpException; // Only import what's needed from dart:io, or avoid it if possible

const _storage = FlutterSecureStorage();

class AuthState {
  final bool isLoading;
  final bool otpSent;
  final bool isAuthenticated;
  final dynamic user;
  final String? error;
  final String? verificationId;

  const AuthState({
    this.isLoading = false, 
    this.otpSent = false, 
    this.isAuthenticated = false,
    this.user,
    this.error,
    this.verificationId
  });

  AuthState copyWith({
    bool? isLoading, 
    bool? otpSent, 
    bool? isAuthenticated,
    dynamic user,
    String? error,
    String? verificationId
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      otpSent: otpSent ?? this.otpSent,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
      verificationId: verificationId ?? this.verificationId,
    );
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(ref.watch(apiClientProvider)),
);

class AuthViewModel extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthViewModel(this._api) : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'nt.access_token');
    if (token != null) {
      state = state.copyWith(isAuthenticated: true);
      await fetchProfile();
    }
  }

  Future<void> fetchProfile() async {
    try {
      final res = await _api.get('/users/me');
      state = state.copyWith(user: res.data['data']);
      
      // Register FCM token after profile is fetched (ensure authenticated)
      await _registerFCMToken();
    } catch (_) {}
  }

  Future<void> _registerFCMToken() async {
    if (kIsWeb) return; // Optional: handle web push later

    try {
      final messaging = FirebaseMessaging.instance;
      
      // Request permissions (especially for iOS)
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await messaging.getToken();
        if (token != null) {
          print('[FCM] Registering token: $token');
          await _api.post('/users/me/fcm-token', data: {'fcmToken': token});
        }
      }
    } catch (e) {
      print('[FCM] Error registering token: $e');
    }
  }

  Future<void> sendOTP(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    // Ensure the phone number is in E.164 format (+977 for Nepal)
    final formattedPhone = phone.startsWith('+') ? phone : '+977$phone';
    
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (optional)
          await _signInWithFirebaseCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          state = state.copyWith(isLoading: false, error: e.message);
        },
        codeSent: (String verificationId, int? resendToken) {
          state = state.copyWith(isLoading: false, otpSent: true, verificationId: verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _signInWithFirebaseCredential(PhoneAuthCredential credential) async {
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken();
    
    if (idToken != null) {
      await _verifyTokenWithBackend(idToken);
    }
  }

  Future<void> _verifyTokenWithBackend(String idToken) async {
    try {
      final res = await _api.post('/auth/firebase/verify', data: {
        'idToken': idToken,
        'deviceId': kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.android ? 'android' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'unknown')),
        'fingerprint': 'mock_fingerprint'
      });
      
      final data = res.data['data'];
      await _storage.write(key: 'nt.access_token', value: data['accessToken']);
      await _storage.write(key: 'nt.refresh_token', value: data['refreshToken']);
      
      state = state.copyWith(isLoading: false, otpSent: false, isAuthenticated: true);
      await fetchProfile();
    } on DioException catch (e) {
      String msg = 'Backend verification failed.';
      if (e.response?.data is Map<String, dynamic>) {
        msg = e.response?.data['message'] ?? msg;
      } else if (e.response?.data is String) {
        msg = e.response?.data;
      }
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> verifyOTP(String phone, String otp) async {
    if (state.verificationId == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: otp,
      );
      await _signInWithFirebaseCredential(credential);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed: $e');
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      final refreshToken = await _storage.read(key: 'nt.refresh_token');
      if (refreshToken != null) {
        await _api.post('/auth/logout', data: {
          'refreshToken': refreshToken,
          'deviceId': kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.android ? 'android' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'unknown'))
        });
      }
    } catch (_) {
      // Ignore errors on logout
    } finally {
      await _storage.delete(key: 'nt.access_token');
      await _storage.delete(key: 'nt.refresh_token');
      state = const AuthState();
    }
  }
}
