import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/solver_result.dart';

class ApiService {
  // IMPORTANT: Change this IP to your WSL IP address
  // Run `wsl hostname -I` in PowerShell to find your WSL IP
  // Default WSL IP is usually 172.x.x.x
  static String baseUrl = 'http://172.17.0.1:5000';

  static void setBaseUrl(String url) {
    baseUrl = url;
  }

  /// Run the full HPC + AI pipeline
  static Future<Map<String, dynamic>> runPipeline() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/run'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(minutes: 10)); // Pipeline can take time

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }

  /// Get execution results (without re-running)
  static Future<SolverResult> getResults() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/results'),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return SolverResult.fromJson(data);
      } else if (response.statusCode == 404) {
        return SolverResult.empty();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch results: $e');
    }
  }

  /// Get list of available graph images
  static Future<List<String>> getImageList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/images'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final images = data['images'] as List<dynamic>? ?? [];
        return images.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get URL for a specific image
  static String getImageUrl(String filename) {
    return '$baseUrl/images/$filename';
  }

  /// Check if backend is alive
  static Future<bool> ping() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ping'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Run a single solver module
  static Future<Map<String, dynamic>> runModule(String module) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/run/$module'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to run $module: $e');
    }
  }
}
