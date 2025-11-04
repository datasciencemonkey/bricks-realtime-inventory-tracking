import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/theme_provider.dart';
import 'screens/landing_page.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload cache in background
  ApiService.preloadCache();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ShadApp(
      title: 'Supply Chain Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ShadThemeData(
        colorScheme: const ShadSlateColorScheme.light(),
        brightness: Brightness.light,
        textTheme: ShadTextTheme.fromGoogleFont(GoogleFonts.dmSans),
      ),
      darkTheme: ShadThemeData(
        colorScheme: const ShadSlateColorScheme.dark(),
        brightness: Brightness.dark,
        textTheme: ShadTextTheme.fromGoogleFont(GoogleFonts.dmSans),
      ),
      home: const LandingPage(),
    );
  }
}
