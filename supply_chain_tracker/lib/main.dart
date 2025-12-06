import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/theme_provider.dart';
import 'screens/landing_page.dart';
import 'services/api_service.dart';
import 'theme/colors.dart';

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

// Custom Databricks Light Color Scheme
const _databricksLightColorScheme = ShadColorScheme(
  // Backgrounds - Oat Light
  background: AppColors.oatLight,
  foreground: AppColors.navy800,
  // Cards
  card: Colors.white,
  cardForeground: AppColors.navy800,
  // Popover
  popover: Colors.white,
  popoverForeground: AppColors.navy800,
  // Primary - Lava (for CTAs and emphasis)
  primary: AppColors.lava600,
  primaryForeground: Colors.white,
  // Secondary - Lava with 15% opacity (for tabs and selections)
  secondary: Color(0x26FF3621), // AppColors.lava600 with 15% opacity
  secondaryForeground: AppColors.navy800,
  // Muted
  muted: AppColors.oatMedium,
  mutedForeground: AppColors.lightTextSecondary,
  // Accent - Lava with 15% transparency (for dropdown selections)
  accent: Color(0x26FF3621), // AppColors.lava600 with 15% opacity
  accentForeground: AppColors.navy800,
  // Destructive - Maroon (alerts, warnings)
  destructive: AppColors.maroon600,
  destructiveForeground: Colors.white,
  // Border
  border: Color(0xFFDDD9D3),
  input: Color(0xFFDDD9D3),
  ring: AppColors.oatLight, // Focus ring - Oat Light
  // Selection - Lava with 15% transparency
  selection: Color(0x26FF3621), // AppColors.lava600 with 15% opacity
);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ShadApp(
      title: 'Supply Chain Control Tower',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ShadThemeData(
        colorScheme: _databricksLightColorScheme,
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
