import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/inventory_item.dart';
import '../models/status_summary.dart';
import '../models/batch_event.dart';
import 'package:latlong2/latlong.dart';

class ApiService {
  // Hybrid approach: Environment variable takes precedence, then debug mode detection
  // Production (release mode): Uses same-origin (empty string)
  // Development (debug mode): Uses localhost:8000
  // Custom: Override with --dart-define=API_BASE_URL=http://your-server:port
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    // Fallback to debug detection
    return kDebugMode ? 'http://localhost:8000' : '';
  }

  // Cache storage
  static List<Map<String, dynamic>>? _batchesCache;
  static List<String>? _productsCache;
  static DateTime? _batchesCacheTime;
  static DateTime? _productsCacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Preload cache on app startup
  static Future<void> preloadCache() async {
    final apiService = ApiService();
    try {
      await Future.wait([
        apiService.getBatches(useCache: false),
        apiService.getProducts(useCache: false),
      ]);
    } catch (e) {
      // Silently fail preload, data will load on demand
      print('Cache preload failed: $e');
    }
  }

  bool _isCacheValid(DateTime? cacheTime) {
    if (cacheTime == null) return false;
    return DateTime.now().difference(cacheTime) < _cacheDuration;
  }

  Future<List<InventoryItem>> getInventory({
    String? product,
    String? status,
  }) async {
    var uri = Uri.parse('$baseUrl/api/inventory');

    final queryParameters = <String, String>{};
    if (product != null) queryParameters['product'] = product;
    if (status != null) queryParameters['status'] = status;

    if (queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => InventoryItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load inventory');
    }
  }

  Future<StatusSummary> getInventorySummary() async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/inventory/summary'));

    if (response.statusCode == 200) {
      return StatusSummary.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load summary');
    }
  }

  Future<List<String>> getProducts({bool useCache = true}) async {
    // Check cache first
    if (useCache && _isCacheValid(_productsCacheTime) && _productsCache != null) {
      return _productsCache!;
    }

    final response = await http.get(Uri.parse('$baseUrl/api/products'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final products = List<String>.from(data['products']);

      // Update cache
      _productsCache = products;
      _productsCacheTime = DateTime.now();

      return products;
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<String>> getStatuses() async {
    final response = await http.get(Uri.parse('$baseUrl/api/statuses'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['statuses']);
    } else {
      throw Exception('Failed to load statuses');
    }
  }

  Future<List<BatchEvent>> getBatchEvents(String batchId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/batch/$batchId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => BatchEvent.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load batch events');
    }
  }

  Future<List<Map<String, dynamic>>> getBatches({bool useCache = true}) async {
    // Check cache first
    if (useCache && _isCacheValid(_batchesCacheTime) && _batchesCache != null) {
      return _batchesCache!;
    }

    final response = await http.get(Uri.parse('$baseUrl/api/batches'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final batches = List<Map<String, dynamic>>.from(data['batches']);

      // Update cache
      _batchesCache = batches;
      _batchesCacheTime = DateTime.now();

      return batches;
    } else {
      throw Exception('Failed to load batches');
    }
  }

  Future<List<LatLng>> getRoute(
      double lat1, double lon1, double lat2, double lon2) async {
    final uri = Uri.parse('$baseUrl/api/route').replace(queryParameters: {
      'lat1': lat1.toString(),
      'lon1': lon1.toString(),
      'lat2': lat2.toString(),
      'lon2': lon2.toString(),
    });

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Return a fake response to trigger fallback
          throw Exception('Timeout');
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> coords = data['coordinates'];
        return coords
            .map((coord) => LatLng(coord[0] as double, coord[1] as double))
            .toList();
      }
    } catch (e) {
      // Fallback to straight line
      return [LatLng(lat1, lon1), LatLng(lat2, lon2)];
    }
    return [LatLng(lat1, lon1), LatLng(lat2, lon2)];
  }
}
