import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

// Provider for executive dashboard data
final executiveDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/dashboard/executive'),
    );

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
    throw Exception('Dashboard API error: $e');
  }
});
