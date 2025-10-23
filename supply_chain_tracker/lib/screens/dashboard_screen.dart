import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/inventory_item.dart';
import '../models/status_summary.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  List<InventoryItem> _inventory = [];
  StatusSummary? _summary;
  bool _isLoading = true;

  // Status colors
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
    setState(() => _isLoading = true);
    try {
      final inventory = await _apiService.getInventory();
      final summary = await _apiService.getInventorySummary();
      setState(() {
        _inventory = inventory;
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    return _statusColors[status] ?? const Color(0xFF95a5a6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚚 Supply Chain Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Cards
                if (_summary != null) _buildSummaryCards(),
                // Map
                Expanded(child: _buildMap()),
                // Legend
                _buildLegend(),
              ],
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildSummaryCard(
            '🚚 In Transit',
            _summary!.inTransit.toString(),
            const Color(0xFFe74c3c),
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            '🏢 At DC',
            _summary!.atDc.toString(),
            const Color(0xFF2ecc71),
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            '⚓ At Dock',
            _summary!.atDock.toString(),
            const Color(0xFF3498db),
          ),
          const SizedBox(width: 8),
          _buildSummaryCard(
            '📊 Total',
            _summary!.totalUnits.toString(),
            const Color(0xFF6DB144),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_inventory.isEmpty) {
      return const Center(child: Text('No inventory data'));
    }

    // Calculate center
    double centerLat = _inventory
            .map((i) => i.latitude)
            .reduce((a, b) => a + b) /
        _inventory.length;
    double centerLon = _inventory
            .map((i) => i.longitude)
            .reduce((a, b) => a + b) /
        _inventory.length;

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
        ),
        CircleLayer(
          circles: _inventory.map((item) {
            return CircleMarker(
              point: LatLng(item.latitude, item.longitude),
              radius: 8,
              color: _getStatusColor(item.status).withOpacity(0.8),
              borderColor: _getStatusColor(item.status),
              borderStrokeWidth: 2,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final uniqueStatuses =
        _inventory.map((i) => i.status).toSet().toList();

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
