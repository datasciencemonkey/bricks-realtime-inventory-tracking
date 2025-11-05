import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';

// Provider for executive dashboard data
final executiveDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await http.get(
    Uri.parse('${ApiService.baseUrl}/api/dashboard/executive'),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Failed to load dashboard data');
  }
});
