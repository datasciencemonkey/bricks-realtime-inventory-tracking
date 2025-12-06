import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/theme_provider.dart';
import 'inventory_screen.dart';
import 'batch_tracking_screen.dart';
import 'executive_dashboard_screen.dart';
import 'planning_screen.dart';

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
          // Header with tabs on the right
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                // Logo and title
                const Text('🚚', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Supply Chain Control Tower',
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
                const SizedBox(width: 32),
                // Tabs
                _buildTab(
                  icon: Icons.dashboard_rounded,
                  label: 'Executive Dashboard',
                  index: 0,
                ),
                const SizedBox(width: 8),
                _buildTab(
                  icon: Icons.inventory_2_rounded,
                  label: 'Real-time Snapshot',
                  index: 1,
                ),
                const SizedBox(width: 8),
                _buildTab(
                  icon: Icons.route_rounded,
                  label: 'Shipment Tracking',
                  index: 2,
                ),
                const SizedBox(width: 8),
                _buildTab(
                  icon: Icons.chat_rounded,
                  label: 'Planning',
                  index: 3,
                ),
                const Spacer(),
                // Theme toggle
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
          // Content
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                const ExecutiveDashboardScreen(),
                const InventoryScreen(),
                const BatchTrackingScreen(),
                PlanningScreen(isVisible: _selectedIndex == 3),
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
