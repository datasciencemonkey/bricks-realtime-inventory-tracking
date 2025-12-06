import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';
import '../providers/inventory_provider.dart';
import '../theme/colors.dart';
import '../widgets/floating_chat_widget.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final ApiService _apiService = ApiService();
  List<InventoryItem> _allInventory = [];
  List<InventoryItem> _filteredInventory = [];
  bool _isLoading = true;

  List<String> _selectedProducts = [];
  List<String> _selectedStatuses = [];
  List<String> _availableProducts = [];
  List<String> _availableStatuses = [];
  bool _isMapMaximized = false;
  bool _highlightDelays = false;
  bool _onlyShowDelays = false;

  // Status colors matching Streamlit
  final Map<String, Color> _statusColors = {
    'In Transit': const Color(0xFFe74c3c),
    'At DC': const Color(0xFF2ecc71),
    'At Dock': const Color(0xFF3498db),
    'Delivered': const Color(0xFF27ae60),
    'In Transit from Supplier': const Color(0xFFe67e22),
    'In Transit to Customer': const Color(0xFFc0392b),
    'In Transit to DC': const Color(0xFF9b59b6),
    'At the Dock': const Color(0xFF1abc9c),
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Check if data is already cached in Riverpod providers
    final inventoryState = ref.read(inventoryProvider);
    final summaryState = ref.read(inventorySummaryProvider);
    final productsState = ref.read(productsListProvider);
    final statusesState = ref.read(statusesListProvider);

    // If data is already available, use it immediately
    bool hasCachedData = false;
    if (inventoryState.hasValue && summaryState.hasValue && 
        productsState.hasValue && statusesState.hasValue) {
      try {
        final inventory = inventoryState.value!;
        final products = productsState.value!;
        final statuses = statusesState.value!
            .where((s) => s.toLowerCase() != 'delivered')
            .toList();

        if (mounted) {
          setState(() {
            _allInventory = inventory;
            _availableProducts = products;
            _availableStatuses = statuses;
            _selectedProducts = [];
            _selectedStatuses = [];
            _filteredInventory = inventory;
            _isLoading = false;
          });
          hasCachedData = true;
        }
      } catch (e) {
        // If cached data has issues, fall through to load fresh data
      }
    }

    // Only show loader if we don't have cached data
    if (!hasCachedData && mounted) {
      setState(() => _isLoading = true);
    }

    // Always refresh data in background to ensure it's up to date
    try {
      final inventory = await _apiService.getInventory();
      final products = await _apiService.getProducts();
      final statuses = (await _apiService.getStatuses())
          .where((s) => s.toLowerCase() != 'delivered')
          .toList();

      if (mounted) {
        setState(() {
          _allInventory = inventory;
          _availableProducts = products;
          _availableStatuses = statuses;
          if (_selectedProducts.isEmpty && _selectedStatuses.isEmpty) {
            _filteredInventory = inventory;
          } else {
            _applyFilters();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredInventory = _allInventory.where((item) {
        final productMatch = _selectedProducts.isEmpty || _selectedProducts.contains(item.productName);
        final statusMatch = _selectedStatuses.isEmpty || _selectedStatuses.contains(item.statusCategory);
        final delayMatch = !_onlyShowDelays || item.isDelayed;
        return productMatch && statusMatch && delayMatch;
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    return _statusColors[status] ?? const Color(0xFF95a5a6);
  }

  /// Build a highlighted marker for delayed shipments with warning icon
  /// Uses the status color as background to match the legend
  Widget _buildDelayedMarker(double size, Color statusColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.maroon600,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroon600.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isMapMaximized) {
      return _buildMaximizedMap();
    }

    return Stack(
      children: [
        Column(
          children: [
            _buildFilters(),
            _buildSummaryCards(),
            Expanded(child: _buildMapWithControls()),
            _buildLegend(),
          ],
        ),
        const FloatingChatWidget(context: ChatContext.realtimeSnapshot),
      ],
    );
  }

  bool get _hasActiveFilters =>
      _selectedProducts.isNotEmpty ||
      _selectedStatuses.isNotEmpty ||
      _onlyShowDelays ||
      _highlightDelays;

  void _clearAllFilters() {
    setState(() {
      _selectedProducts = [];
      _selectedStatuses = [];
      _highlightDelays = false;
      _onlyShowDelays = false;
      _filteredInventory = _allInventory;
    });
  }

  Widget _buildFilters() {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildProductFilter(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatusFilter(),
          ),
          const SizedBox(width: 16),
          // Clear All Filters button - aligned with filter dropdowns
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Empty label spacer to match filter label height
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Text(
                  ' ', // Empty label for alignment
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ShadButton.outline(
                onPressed: _hasActiveFilters ? _clearAllFilters : null,
                size: ShadButtonSize.sm,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt_off_rounded,
                      size: 16,
                      color: _hasActiveFilters
                          ? theme.colorScheme.foreground
                          : theme.colorScheme.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Clear Filters',
                      style: TextStyle(
                        color: _hasActiveFilters
                            ? theme.colorScheme.foreground
                            : theme.colorScheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductFilter() {
    final theme = ShadTheme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            'Filter by Product',
            style: theme.textTheme.small.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ShadSelect<String>.multiple(
          key: ValueKey('products_${_selectedProducts.length}'),
          minWidth: 300,
          allowDeselection: true,
          closeOnSelect: false,
          initialValues: _selectedProducts.toSet(),
          placeholder: const Text('Select products...'),
          options: _availableProducts
              .map((product) => ShadOption(value: product, child: Text(product)))
              .toList(),
          selectedOptionsBuilder: (context, values) {
            if (values.isEmpty) {
              return const Text('Select products...');
            }
            return Text(
              values.length == _availableProducts.length
                  ? 'All products (${values.length})'
                  : '${values.length} product${values.length == 1 ? '' : 's'} selected',
            );
          },
          onChanged: (values) {
            setState(() {
              _selectedProducts = values.toList();
              _applyFilters();
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    final theme = ShadTheme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            'Filter by Status',
            style: theme.textTheme.small.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ShadSelect<String>.multiple(
          key: ValueKey('statuses_${_selectedStatuses.length}'),
          minWidth: 300,
          allowDeselection: true,
          closeOnSelect: false,
          initialValues: _selectedStatuses.toSet(),
          placeholder: const Text('Select statuses...'),
          options: _availableStatuses
              .map((status) => ShadOption(value: status, child: Text(status)))
              .toList(),
          selectedOptionsBuilder: (context, values) {
            if (values.isEmpty) {
              return const Text('Select statuses...');
            }
            return Text(
              values.length == _availableStatuses.length
                  ? 'All statuses (${values.length})'
                  : '${values.length} status${values.length == 1 ? '' : 'es'} selected',
            );
          },
          onChanged: (values) {
            setState(() {
              _selectedStatuses = values.toList();
              _applyFilters();
            });
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    // Calculate filtered summary based on product/status filters (not delay filter)
    // We need to count delays from the product/status filtered set, not including delay filter
    final baseFilteredInventory = _allInventory.where((item) {
      final productMatch = _selectedProducts.isEmpty || _selectedProducts.contains(item.productName);
      final statusMatch = _selectedStatuses.isEmpty || _selectedStatuses.contains(item.statusCategory);
      return productMatch && statusMatch;
    }).toList();

    final inTransit = _filteredInventory.where((item) => item.statusCategory == 'In Transit').length;
    final atDc = _filteredInventory.where((item) => item.statusCategory == 'At DC').length;
    final atDock = _filteredInventory.where((item) => item.statusCategory == 'At Dock').length;
    final totalUnits = _filteredInventory.fold<int>(0, (sum, item) => sum + item.qty);
    final delayedCount = baseFilteredInventory.where((item) => item.isDelayed).length;

    // Calculate total dollar value (qty * unit_price)
    final totalValue = _filteredInventory.fold<double>(
      0.0,
      (sum, item) => sum + (item.qty * item.unitPrice),
    );

    // Format total value (e.g., $1.2M, $850K, or $1,234)
    String formatValue(double value) {
      if (value >= 1000000) {
        return '\$${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value >= 1000) {
        return '\$${(value / 1000).toStringAsFixed(0)}K';
      } else {
        return '\$${value.toStringAsFixed(0)}';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricCard(
            '🚚 In Transit',
            inTransit.toString(),
            const Color(0xFFe74c3c),
          ),
          const SizedBox(width: 8),
          _buildMetricCard(
            '🏢 At DC',
            atDc.toString(),
            const Color(0xFF2ecc71),
          ),
          const SizedBox(width: 8),
          _buildMetricCard(
            '⚓ At Dock',
            atDock.toString(),
            const Color(0xFF3498db),
          ),
          const SizedBox(width: 8),
          _buildMetricCard(
            '📊 Total Units',
            NumberFormat('#,###').format(totalUnits),
            const Color(0xFF6DB144),
          ),
          const SizedBox(width: 8),
          _buildMetricCard(
            '💰 Total Value',
            formatValue(totalValue),
            const Color(0xFF9b59b6),
          ),
          const SizedBox(width: 8),
          // Delays card with integrated controls
          _buildDelaysCard(delayedCount),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Expanded(
      child: ShadCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: ShadTheme.of(context).textTheme.muted.copyWith(
                    fontSize: 12,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: ShadTheme.of(context).textTheme.h3.copyWith(
                      color: color,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDelaysCard(int delayedCount) {
    final theme = ShadTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDelays = delayedCount > 0;

    // Theme-aware colors for delays card
    final mutedColor = theme.colorScheme.mutedForeground;
    final delayTitleColor = isDark ? AppColors.yellow600 : AppColors.navy800;
    final delayCountColor = isDark ? const Color(0xFFFF6B6B) : AppColors.maroon600; // Brighter red for dark mode

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: hasDelays
              ? AppColors.yellow600.withValues(alpha: isDark ? 0.15 : 0.1)
              : theme.colorScheme.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasDelays
                ? (isDark ? AppColors.yellow600.withValues(alpha: 0.6) : AppColors.maroon600)
                : theme.colorScheme.border,
            width: hasDelays ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row with icon
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: hasDelays ? AppColors.yellow600 : mutedColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hasDelays ? 'Delays Detected' : 'Delays',
                    style: theme.textTheme.muted.copyWith(
                      fontSize: 12,
                      color: hasDelays ? delayTitleColor : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Count
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                delayedCount.toString(),
                style: theme.textTheme.h3.copyWith(
                  color: hasDelays ? delayCountColor : mutedColor,
                ),
              ),
            ),
            // Controls - only shown when there are delays
            if (hasDelays) ...[
              const SizedBox(height: 8),
              // Highlight on Map checkbox
              InkWell(
                onTap: () {
                  setState(() {
                    _highlightDelays = !_highlightDelays;
                    if (!_highlightDelays) {
                      _onlyShowDelays = false;
                      _applyFilters();
                    }
                  });
                },
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: ShadCheckbox(
                        value: _highlightDelays,
                        onChanged: (value) {
                          setState(() {
                            _highlightDelays = value;
                            if (!value) {
                              _onlyShowDelays = false;
                              _applyFilters();
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Highlight on Map',
                        style: theme.textTheme.small.copyWith(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Show Only Delays checkbox
              InkWell(
                onTap: () {
                  setState(() {
                    _onlyShowDelays = !_onlyShowDelays;
                    if (_onlyShowDelays) {
                      _highlightDelays = true;
                    }
                    _applyFilters();
                  });
                },
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: ShadCheckbox(
                        value: _onlyShowDelays,
                        onChanged: (value) {
                          setState(() {
                            _onlyShowDelays = value;
                            if (value) {
                              _highlightDelays = true;
                            }
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Show Only Delays',
                        style: theme.textTheme.small.copyWith(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapWithControls() {
    return Stack(
      children: [
        _buildMap(),
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            onPressed: () {
              setState(() {
                _isMapMaximized = true;
              });
            },
            tooltip: 'Maximize Map',
            child: const Icon(Icons.fullscreen),
          ),
        ),
      ],
    );
  }

  Widget _buildMaximizedMap() {
    return Stack(
      children: [
        _buildMap(),
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            onPressed: () {
              setState(() {
                _isMapMaximized = false;
              });
            },
            tooltip: 'Exit Fullscreen',
            child: const Icon(Icons.fullscreen_exit),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: _buildLegend(),
        ),
      ],
    );
  }

  Widget _buildMap() {
    if (_filteredInventory.isEmpty) {
      return const Center(child: Text('No inventory data matches filters'));
    }

    double centerLat = _filteredInventory
            .map((i) => i.latitude)
            .reduce((a, b) => a + b) /
        _filteredInventory.length;
    double centerLon = _filteredInventory
            .map((i) => i.longitude)
            .reduce((a, b) => a + b) /
        _filteredInventory.length;

    // Group items by location to show aggregated data in tooltips
    Map<String, List<InventoryItem>> locationGroups = {};
    for (var item in _filteredInventory) {
      final key = '${item.latitude.toStringAsFixed(6)},${item.longitude.toStringAsFixed(6)}';
      locationGroups.putIfAbsent(key, () => []).add(item);
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLon),
        initialZoom: 4.0,
        minZoom: 2.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.supplychain.supply_chain_tracker',
          tileProvider: CancellableNetworkTileProvider(),
        ),
        MarkerLayer(
          markers: locationGroups.entries.map((entry) {
            final items = entry.value;
            final firstItem = items.first;
            final totalQty = items.fold<int>(0, (sum, item) => sum + item.qty);
            final totalShipments = items.length;
            final location = firstItem.currentLocation;

            // Find the dominant detailed status (most common one)
            final statusCounts = <String, int>{};
            for (var item in items) {
              statusCounts[item.status] = (statusCounts[item.status] ?? 0) + 1;
            }
            final dominantStatus = statusCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

            // Check if any items have expected arrival time
            final itemsWithETA = items.where((item) => item.expectedArrivalTime.isNotEmpty).toList();
            String? etaInfo;
            if (itemsWithETA.isNotEmpty) {
              // Show the earliest ETA if multiple items have ETA
              final etas = itemsWithETA.map((item) => item.expectedArrivalTime).toList();
              etas.sort();
              etaInfo = 'ETA: ${etas.first}';
            }

            // Check if any items in this location are delayed
            final hasDelayedItems = items.any((item) => item.isDelayed);
            final delayedItemCount = items.where((item) => item.isDelayed).length;

            // Get unique product names at this location
            final productNames = items.map((item) => item.productName).toSet().toList();
            final productsDisplay = productNames.length <= 2
                ? productNames.join(', ')
                : '${productNames.take(2).join(', ')} +${productNames.length - 2} more';

            // Build tooltip message
            String tooltipMessage = '$location\n$productsDisplay\n$totalShipments shipments\n$totalQty units\n$dominantStatus';
            if (etaInfo != null) {
              tooltipMessage += '\n$etaInfo';
            }
            if (hasDelayedItems) {
              tooltipMessage += '\n⚠️ $delayedItemCount delayed';
            }

            // Determine marker appearance based on delay status
            final bool showDelayHighlight = _highlightDelays && hasDelayedItems;
            final statusColor = _getStatusColor(dominantStatus);
            final markerSize = showDelayHighlight ? 28.0 : 20.0;

            return Marker(
              point: LatLng(firstItem.latitude, firstItem.longitude),
              width: markerSize,
              height: markerSize,
              child: Tooltip(
                message: tooltipMessage,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.4,
                ),
                child: showDelayHighlight
                    ? _buildDelayedMarker(markerSize, statusColor)
                    : Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: statusColor,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final uniqueStatuses =
        _filteredInventory.map((i) => i.status).toSet().toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎨 Status Legend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: uniqueStatuses.map((status) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

}
