import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage { en, ne }

final languageProvider = StateProvider<AppLanguage>((ref) => AppLanguage.en);

class AppStrings {
  final AppLanguage lang;
  AppStrings(this.lang);

  String get createVault => lang == AppLanguage.en ? 'Create Vault' : 'भल्ट बनाउनुहोस्';
  String get vaultTitle => lang == AppLanguage.en ? 'Vault Title' : 'भल्टको शीर्षक';
  String get amount => lang == AppLanguage.en ? 'Amount (NPR)' : 'रकम (नेपाली रुपैयाँ)';
  String get counterpartyPhone => lang == AppLanguage.en ? 'Counterparty Phone' : 'अर्को पक्षको फोन नम्बर';
  String get totalToLock => lang == AppLanguage.en ? 'TOTAL TO LOCK' : 'जम्मा लक गर्नुपर्ने रकम';
  String get createSecureVault => lang == AppLanguage.en ? 'Create Secure Vault' : 'सुरक्षित भल्ट बनाउनुहोस्';
  String get subtotal => lang == AppLanguage.en ? 'Subtotal' : 'जम्मा';
  String get platformFee => lang == AppLanguage.en ? 'Platform Fee' : 'प्लेटफर्म शुल्क';
  String get secureEscrow => lang == AppLanguage.en ? 'Secure Escrow' : 'सुरक्षित एस्क्रो';
  String get fundsHeldSafely => lang == AppLanguage.en ? 'FUNDS HELD SAFELY UNTIL DELIVERY' : 'सामान प्राप्त नभएसम्म रकम सुरक्षित रहन्छ';
}

final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(languageProvider);
  return AppStrings(lang);
});
