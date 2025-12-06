import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

// Provider for executive dashboard data
final executiveDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final url = '${ApiService.baseUrl}/api/dashboard/executive';
  debugPrint('Dashboard API URL: $url');

  try {
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Request timeout after 10 seconds');
      },
    );

    debugPrint('Dashboard response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      // Check if response is actually JSON
      if (response.body.trim().startsWith('{') || response.body.trim().startsWith('[')) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Server returned non-JSON response: ${response.body.substring(0, 100)}');
      }
    } else {
      throw Exception('Failed to load dashboard data: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Dashboard error: $e');
    throw Exception('Dashboard API error: $e');
  }
});
