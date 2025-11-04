import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../widgets/particle_background.dart';
import '../widgets/text_reveal_chaos.dart';
import '../widgets/background_ripples.dart';
import '../providers/inventory_provider.dart';
import 'main_screen.dart';

class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends ConsumerState<LandingPage> {
  bool _isDataReady = false;
  bool _startTextReveal = false;
  bool _textAnimationComplete = false;
  bool _isHovering = false;

  // Databricks Orange color
  static const Color databricksOrange = Color(0xFFFF3621);

  // Green tinge for ripples
  static const Color greenTinge = Color(0xFF6DB144);

  bool get _showLaunchButton => _textAnimationComplete && _isDataReady;

  @override
  void initState() {
    super.initState();
    // Start text reveal animation after a brief delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _startTextReveal = true;
        });
      }
    });

    // Mark text animation as complete after it finishes
    // Animation starts at 800ms and takes 3000ms, so total is ~3800ms
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        setState(() {
          _textAnimationComplete = true;
        });
      }
    });

    // Pre-fetch data in background
    _prefetchData();
  }

  Future<void> _prefetchData() async {
    // Start pre-fetching immediately
    ref.read(prefetchDataProvider.future).then((_) {
      if (mounted) {
        setState(() {
          _isDataReady = true;
        });
      }
    }).catchError((error) {
      // Even if there's an error, allow the user to proceed
      if (mounted) {
        setState(() {
          _isDataReady = true;
        });
      }
    });
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefetchState = ref.watch(prefetchDataProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Particle animation background
          Positioned.fill(
            child: ParticleBackground(
              particleCount: 150,
              particleColor: isDark
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : theme.colorScheme.primary.withValues(alpha: 0.4),
              particleSize: 3.0,
              connectParticles: true,
              connectionDistance: 100.0,
            ),
          ),
          // Content overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo/icon with background ripples
                BackgroundRipples(
                  color: greenTinge,
                  numberOfRipples: 3,
                  minRadius: 40,
                  maxRadius: 80,
                  duration: const Duration(seconds: 4),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // App title
                Text(
                  'Supply Chain Tracker',
                  style: GoogleFonts.dmSans(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.foreground,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Animated text: "Experience the power of full stack data intelligence..."
                EnhancedTextRevealEffect(
                  text: 'Experience the power of full stack data intelligence...',
                  trigger: _startTextReveal,
                  strategy: FlyingCharactersStrategy(
                    maxOffset: 50,
                    randomDirection: true,
                    enableBlur: true,
                  ),
                  unit: AnimationUnit.character,
                  textStyle: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Launch button (appears after animation)
                AnimatedOpacity(
                  opacity: _showLaunchButton ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: AnimatedScale(
                    scale: _showLaunchButton ? 1.0 : 0.8,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _isHovering = true),
                      onExit: (_) => setState(() => _isHovering = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: _isHovering ? databricksOrange : Colors.white,
                          boxShadow: _isHovering
                              ? [
                                  BoxShadow(
                                    color: databricksOrange.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isDataReady ? _navigateToMain : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 16,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Launch Now',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _isHovering
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: _isHovering
                                        ? Colors.white
                                        : Colors.black,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Show loading indicator only while fetching
                if (!_isDataReady && prefetchState.isLoading) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

