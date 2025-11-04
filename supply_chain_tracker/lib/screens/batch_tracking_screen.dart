import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'dart:async';
import '../models/batch_event.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';

class BatchTrackingScreen extends StatefulWidget {
  const BatchTrackingScreen({super.key});

  @override
  State<BatchTrackingScreen> createState() => _BatchTrackingScreenState();
}

class _BatchTrackingScreenState extends State<BatchTrackingScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _batches = [];
  List<BatchEvent> _events = [];
  String? _selectedBatchId;
  String? _selectedProductName;
  bool _isLoading = true;
  bool _eventsLoading = false;
  List<LatLng> _routeCoordinates = [];
  String _productSearchValue = '';
  String _batchSearchValue = '';

  // Animation state
  bool _isAnimating = false;
  int _currentAnimationStep = 0;
  String _currentStatus = '';
  Timer? _animationTimer;
  bool _isMapMaximized = false;

  // Computed properties
  List<String> get _productNames {
    return _batches
        .map((b) => b['product_name'] as String)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> get _filteredProductNames {
    if (_productSearchValue.isEmpty) return _productNames;
    return _productNames
        .where((name) =>
            name.toLowerCase().contains(_productSearchValue.toLowerCase()))
        .toList();
  }

  List<Map<String, dynamic>> get _filteredBatches {
    if (_selectedProductName == null) return _batches;
    var batches = _batches
        .where((b) => b['product_name'] == _selectedProductName)
        .toList();

    if (_batchSearchValue.isEmpty) return batches;
    return batches
        .where((b) => (b['batch_id'] as String)
            .toLowerCase()
            .contains(_batchSearchValue.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBatches() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final batches = await _apiService.getBatches();
      if (mounted) {
        setState(() {
          _batches = batches;
          _isLoading = false;
          // Don't auto-select, let user choose
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Use addPostFrameCallback to ensure context is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading batches: $e')),
            );
          }
        });
      }
    }
  }

  Future<void> _loadBatchEvents() async {
    if (_selectedBatchId == null) return;

    if (mounted) {
      setState(() => _eventsLoading = true);
    }
    try {
      final events = await _apiService.getBatchEvents(_selectedBatchId!).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout loading batch events');
        },
      );

      if (!mounted) return;

      // Build route with OSRM - with timeout protection
      List<LatLng> allRouteCoords = [];
      for (int i = 0; i < events.length - 1; i++) {
        if (!mounted) return; // Check if widget is still mounted

        final curr = events[i];
        final next = events[i + 1];

        try {
          final routeSegment = await _apiService.getRoute(
            curr.entityLatitude,
            curr.entityLongitude,
            next.entityLatitude,
            next.entityLongitude,
          );
          if (i == 0) {
            allRouteCoords.addAll(routeSegment);
          } else {
            allRouteCoords.addAll(routeSegment.skip(1));
          }
        } catch (e) {
          // If route fails, use straight line
          if (i == 0) {
            allRouteCoords.add(LatLng(curr.entityLatitude, curr.entityLongitude));
          }
          allRouteCoords.add(LatLng(next.entityLatitude, next.entityLongitude));
        }
      }

      if (mounted) {
        setState(() {
          _events = events;
          _routeCoordinates = allRouteCoords;
          _eventsLoading = false;
          _currentAnimationStep = 0;
          _currentStatus = events.isNotEmpty ? events[0].event : '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _eventsLoading = false);
        // Use addPostFrameCallback to ensure context is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading events: $e')),
            );
          }
        });
      }
    }
  }

  void _startTrackingAnimation() {
    if (_routeCoordinates.isEmpty || _events.isEmpty) return;

    setState(() {
      _isAnimating = true;
      _currentAnimationStep = 0;
      _currentStatus = _events[0].event;
    });

    // Animation at 30fps for 5 seconds = 150 frames (faster animation)
    const framesPerSecond = 30;
    const animationDuration = 5; // seconds
    const totalFrames = framesPerSecond * animationDuration;
    const frameDuration = Duration(milliseconds: 1000 ~/ framesPerSecond); // ~33ms per frame

    final totalSteps = _routeCoordinates.length;

    int currentFrame = 0;
    _animationTimer = Timer.periodic(frameDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      currentFrame++;

      if (currentFrame >= totalFrames) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isAnimating = false;
            _currentAnimationStep = totalSteps - 1;
            _currentStatus = _events.last.event;
          });
        }
        return;
      }

      // Calculate which route coordinate to show based on current frame
      final progress = currentFrame / totalFrames; // 0.0 to 1.0
      final stepIndex = (progress * (totalSteps - 1)).round();
      final currentCoord = _routeCoordinates[stepIndex];

      // Find which event point we're closest to
      int closestEventIndex = 0;
      double minDistance = double.infinity;

      for (int i = 0; i < _events.length; i++) {
        final event = _events[i];
        final eventCoord = LatLng(event.entityLatitude, event.entityLongitude);
        final distance = _calculateDistance(currentCoord, eventCoord);
        if (distance < minDistance) {
          minDistance = distance;
          closestEventIndex = i;
        }
      }

      if (mounted) {
        setState(() {
          _currentAnimationStep = stepIndex;
          _currentStatus = _events[closestEventIndex].event;
        });
      }
    });
  }

  void _stopTrackingAnimation() {
    _animationTimer?.cancel();
    if (mounted) {
      setState(() {
        _isAnimating = false;
      });
    }
  }

  double _calculateDistance(LatLng coord1, LatLng coord2) {
    final lat1 = coord1.latitude;
    final lon1 = coord1.longitude;
    final lat2 = coord2.latitude;
    final lon2 = coord2.longitude;
    return ((lat1 - lat2).abs() + (lon1 - lon2).abs());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isMapMaximized) {
      return _buildMaximizedMap(isDark);
    }

    return Column(
      children: [
        _buildControls(isDark),
        if (_eventsLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_events.isNotEmpty) ...[
          Expanded(child: _buildMapWithControls()),
          _buildTimeline(isDark),
        ] else
          const Expanded(child: Center(child: Text('No events found'))),
      ],
    );
  }

  Widget _buildControls(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product', style: ShadTheme.of(context).textTheme.small),
                    const SizedBox(height: 4),
                    ShadSelect<String>.withSearch(
                      minWidth: 180,
                      placeholder: const Text('Select product...'),
                      onSearchChanged: (value) =>
                          setState(() => _productSearchValue = value),
                      searchPlaceholder: const Text('Search products'),
                      options: [
                        if (_filteredProductNames.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('No products found'),
                          ),
                        ..._productNames.map(
                          (name) {
                            return Offstage(
                              offstage: !_filteredProductNames.contains(name),
                              child: ShadOption(
                                value: name,
                                child: Text(name),
                              ),
                            );
                          },
                        )
                      ],
                      selectedOptionBuilder: (context, value) => Text(value),
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {
                            _selectedProductName = value;
                            _selectedBatchId = null;
                            _events = [];
                            _routeCoordinates = [];
                            _stopTrackingAnimation();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Batch', style: ShadTheme.of(context).textTheme.small),
                    const SizedBox(height: 4),
                    ShadSelect<String>.withSearch(
                      minWidth: 180,
                      placeholder: const Text('Select batch...'),
                      enabled: _selectedProductName != null,
                      onSearchChanged: (value) =>
                          setState(() => _batchSearchValue = value),
                      searchPlaceholder: const Text('Search batches'),
                      options: [
                        if (_selectedProductName != null && _filteredBatches.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('No batches found'),
                          ),
                        ..._batches
                            .where((b) => b['product_name'] == _selectedProductName)
                            .map(
                          (batch) {
                            final batchId = batch['batch_id'] as String;
                            return Offstage(
                              offstage: !_filteredBatches
                                  .any((b) => b['batch_id'] == batchId),
                              child: ShadOption(
                                value: batchId,
                                child: Text(batchId),
                              ),
                            );
                          },
                        )
                      ],
                      selectedOptionBuilder: (context, value) => Text(value),
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {
                            _selectedBatchId = value;
                            _stopTrackingAnimation();
                            _loadBatchEvents();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _routeCoordinates.isEmpty
                    ? null
                    : (_isAnimating
                        ? _stopTrackingAnimation
                        : _startTrackingAnimation),
                icon: Icon(_isAnimating ? Icons.stop : Icons.play_arrow, size: 16),
                label: Text(_isAnimating ? 'Stop Tracking' : 'Track History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAnimating ? Colors.red : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDisplay(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.sunriseOrange.withValues(alpha: 0.9),
            AppColors.goldenHarvest.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.sunriseOrange.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Current Status',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            '🚚',
            style: TextStyle(fontSize: 36),
          ),
        ],
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

  Widget _buildMaximizedMap(bool isDark) {
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
          child: _buildTimeline(isDark),
        ),
      ],
    );
  }

  Widget _buildMap() {
    if (_events.isEmpty) {
      return const Center(child: Text('No events to display'));
    }

    double centerLat = _events.map((e) => e.entityLatitude).reduce((a, b) => a + b) / _events.length;
    double centerLon = _events.map((e) => e.entityLongitude).reduce((a, b) => a + b) / _events.length;

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLon),
        initialZoom: 5.0,
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
        // Route line
        if (_routeCoordinates.isNotEmpty)
          PolylineLayer(
            polylines: [
              // Shadow/outline for better visibility
              Polyline(
                points: _routeCoordinates,
                strokeWidth: 8.0,
                color: Colors.black.withValues(alpha: 0.3),
              ),
              // Main route line
              Polyline(
                points: _routeCoordinates,
                strokeWidth: 5.0,
                color: AppColors.unfiGreen,
              ),
            ],
          ),
        // Event markers
        MarkerLayer(
          markers: _buildEventMarkers(),
        ),
        // Truck marker if animation is active
        if (_isAnimating && _routeCoordinates.isNotEmpty)
          MarkerLayer(
            markers: [_buildTruckMarker()],
          ),
      ],
    );
  }

  List<Marker> _buildEventMarkers() {
    final markers = <Marker>[];
    for (int i = 0; i < _events.length; i++) {
      final event = _events[i];
      final eventNumber = i + 1;
      final color = i == 0
          ? AppColors.statusDelivered
          : i == _events.length - 1
              ? AppColors.statusInTransit
              : AppColors.statusAtDC;

      markers.add(
        Marker(
          point: LatLng(event.entityLatitude, event.entityLongitude),
          width: 50,
          height: 70,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$eventNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  event.event.split(' ').take(2).join(' '),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return markers;
  }

  Marker _buildTruckMarker() {
    final truckCoord = _routeCoordinates[
        _currentAnimationStep.clamp(0, _routeCoordinates.length - 1)];

    return Marker(
      point: truckCoord,
      width: 60,
      height: 60,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.sunriseOrange,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.sunriseOrange.withValues(alpha: 0.6),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '🚚',
            style: TextStyle(fontSize: 36),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ShadCard(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.timeline,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Event Timeline',
                    style: ShadTheme.of(context).textTheme.large,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _events.length * 2 - 1,
                itemBuilder: (context, index) {
                  if (index.isOdd) {
                    // Separator
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 40),
                          Icon(
                            Icons.arrow_downward,
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  }

                  final eventIndex = index ~/ 2;
                  final event = _events[eventIndex];
                  final isFirst = eventIndex == 0;
                  final isLast = eventIndex == _events.length - 1;

                  return ShadCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isFirst
                                ? AppColors.statusDelivered
                                : isLast
                                    ? AppColors.statusInTransit
                                    : AppColors.statusAtDC,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isFirst
                                ? '🏭 START'
                                : isLast
                                    ? '🎯 END'
                                    : 'Step ${eventIndex + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.event,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event.entityLocation,
                                      style: const TextStyle(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              event.eventTimeCstReadable,
                              style: const TextStyle(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
