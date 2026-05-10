import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/core/router/app_router.dart';
import 'src/core/localization/app_strings.dart';
import 'src/core/theme/nt_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: TrustNepalApp()));
}

class TrustNepalApp extends ConsumerWidget {
  const TrustNepalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Trust Nepal Escrow',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: NTColors.primary,
          secondary: NTColors.secondary,
          tertiary: NTColors.tertiary,
          surface: NTColors.background,
          onSurface: NTColors.onSurface,
          error: NTColors.error,
        ),
        textTheme: lang == AppLanguage.en
            ? GoogleFonts.publicSansTextTheme(ThemeData.light().textTheme)
            : GoogleFonts.muktaTextTheme(ThemeData.light().textTheme),
        scaffoldBackgroundColor: NTColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: NTColors.primary),
        ),
      ),
    );
  }
}
