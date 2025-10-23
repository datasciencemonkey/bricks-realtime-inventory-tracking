import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/inventory_item.dart';
import '../models/status_summary.dart';
import '../services/api_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ApiService _apiService = ApiService();
  List<InventoryItem> _allInventory = [];
  List<InventoryItem> _filteredInventory = [];
  StatusSummary? _summary;
  bool _isLoading = true;

  List<String> _selectedProducts = [];
  List<String> _selectedStatuses = [];
  List<String> _availableProducts = [];
  List<String> _availableStatuses = [];
  bool _showDataTable = false;
  bool _isMapMaximized = false;

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
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final inventory = await _apiService.getInventory();
      final summary = await _apiService.getInventorySummary();
      final products = await _apiService.getProducts();
      final statuses = await _apiService.getStatuses();

      if (mounted) {
        setState(() {
          _allInventory = inventory;
          _availableProducts = products;
          _availableStatuses = statuses;
          _selectedProducts = []; // Start with none selected
          _selectedStatuses = []; // Start with none selected
          _filteredInventory = inventory;
          _summary = summary;
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
        return productMatch && statusMatch;
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    return _statusColors[status] ?? const Color(0xFF95a5a6);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isMapMaximized) {
      return _buildMaximizedMap();
    }

    return Column(
      children: [
        _buildFilters(),
        _buildSummaryCards(),
        Expanded(child: _buildMapWithControls()),
        _buildLegend(),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMultiSelect(
                  label: 'Filter by Product',
                  items: _availableProducts,
                  selectedItems: _selectedProducts,
                  onChanged: (values) {
                    setState(() {
                      _selectedProducts = values;
                      _applyFilters();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              ShadCard(
                backgroundColor: const Color(0xFF6DB144),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Total Shipments',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      '${_filteredInventory.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMultiSelect(
            label: 'Filter by Status',
            items: _availableStatuses,
            selectedItems: _selectedStatuses,
            onChanged: (values) {
              setState(() {
                _selectedStatuses = values;
                _applyFilters();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelect({
    required String label,
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onChanged,
  }) {
    final allSelected = selectedItems.length == items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.start,
            alignment: WrapAlignment.start,
            children: [
              // Select All button
              ActionChip(
                label: Text(allSelected ? 'Select All (${items.length})' : 'Select All'),
                backgroundColor: allSelected ? Colors.blue.withOpacity(0.2) : null,
                onPressed: () => onChanged(List.from(items)),
              ),
              // Clear All button
              ActionChip(
                label: const Text('Clear All'),
                onPressed: () => onChanged([]),
              ),
              // Show count if some selected
              if (selectedItems.isNotEmpty && !allSelected)
                Chip(
                  label: Text('${selectedItems.length} selected'),
                  backgroundColor: Colors.grey.withOpacity(0.2),
                ),
              // Individual filter chips for each item
              ...items.map((item) {
                final isSelected = selectedItems.contains(item);
                return FilterChip(
                  label: Text(item),
                  selected: isSelected,
                  onSelected: (selected) {
                    List<String> newSelection = List.from(selectedItems);
                    if (selected) {
                      newSelection.add(item);
                    } else {
                      newSelection.remove(item);
                    }
                    onChanged(newSelection);
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    // Calculate filtered summary
    final inTransit = _filteredInventory.where((item) => item.statusCategory == 'In Transit').length;
    final atDc = _filteredInventory.where((item) => item.statusCategory == 'At DC').length;
    final atDock = _filteredInventory.where((item) => item.statusCategory == 'At Dock').length;
    final totalUnits = _filteredInventory.fold<int>(0, (sum, item) => sum + item.qty);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildSummaryCard(
            '🚚 In Transit',
            inTransit.toString(),
            const Color(0xFFe74c3c),
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            '🏢 At DC',
            atDc.toString(),
            const Color(0xFF2ecc71),
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            '⚓ At Dock',
            atDock.toString(),
            const Color(0xFF3498db),
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            '📊 Total Units',
            totalUnits.toString(),
            const Color(0xFF6DB144),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: ShadCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: ShadTheme.of(context).textTheme.muted.copyWith(
                    fontSize: 12,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: ShadTheme.of(context).textTheme.h3.copyWith(
                    color: color,
                  ),
            ),
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

            return Marker(
              point: LatLng(firstItem.latitude, firstItem.longitude),
              width: 20,
              height: 20,
              child: Tooltip(
                message: '$location\n$totalShipments shipments\n$totalQty units\n$dominantStatus',
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _getStatusColor(dominantStatus).withOpacity(0.8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getStatusColor(dominantStatus),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
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

  Widget _buildDataTableToggle() {
    return ExpansionTile(
      title: const Text('📊 View Detailed Data'),
      initiallyExpanded: _showDataTable,
      onExpansionChanged: (expanded) {
        setState(() => _showDataTable = expanded);
      },
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Reference')),
              DataColumn(label: Text('Product')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Qty')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Location')),
              DataColumn(label: Text('Destination')),
            ],
            rows: _filteredInventory.map((item) {
              return DataRow(cells: [
                DataCell(Text(item.referenceNumber)),
                DataCell(Text(item.productName)),
                DataCell(Text(item.status)),
                DataCell(Text(item.qty.toString())),
                DataCell(Text('\$${item.unitPrice.toStringAsFixed(2)}')),
                DataCell(Text(item.currentLocation)),
                DataCell(Text(item.destination)),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
