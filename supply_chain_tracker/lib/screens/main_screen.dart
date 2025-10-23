import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/theme_provider.dart';
import 'inventory_screen.dart';
import 'batch_tracking_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text('🚚', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Supply Chain Tracker',
                        style: theme.textTheme.large.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Real-time Inventory Management',
                        style: theme.textTheme.muted.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(themeModeProvider.notifier).toggleTheme(),
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.wb_sunny_rounded
                        : Icons.nightlight_round,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.border,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildTab(
                  icon: Icons.inventory_2_rounded,
                  label: 'Real-time Inventory',
                  index: 0,
                ),
                const SizedBox(width: 8),
                _buildTab(
                  icon: Icons.route_rounded,
                  label: 'Batch Tracking',
                  index: 1,
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                InventoryScreen(),
                BatchTrackingScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    final theme = ShadTheme.of(context);

    return TextButton.icon(
      onPressed: () => setState(() => _selectedIndex = index),
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? theme.colorScheme.secondary : Colors.transparent,
        foregroundColor: isSelected ? theme.colorScheme.secondaryForeground : theme.colorScheme.foreground,
      ),
    );
  }
}
