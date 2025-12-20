import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator to access localhost of the computer
  // Use your computer's LAN IP (e.g., 192.168.1.5) for physical device
  static const String baseUrl = 'http://localhost:5000/api';

  // Register User
  static Future<Map<String, dynamic>> registerUser(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data; 
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Login User
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Redeem Points
  static Future<Map<String, dynamic>> claimPoints(String tokenValue) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      throw Exception('User not logged in');
    }

    final url = Uri.parse('$baseUrl/recycle/claim');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'tokenValue': tokenValue,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data; // Success
      } else {
        throw Exception(data['message'] ?? 'Failed to claim points');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Get User Details (Fetch latest points)
  static Future<Map<String, dynamic>> getUserDetails(String userId) async {
    final url = Uri.parse('$baseUrl/user/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load user');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Get User History
  static Future<List<dynamic>> getHistory(String userId) async {
    final url = Uri.parse('$baseUrl/history/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load history');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Get Challenges
  static Future<List<dynamic>> getChallenges() async {
    final url = Uri.parse('$baseUrl/challenges');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load challenges');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Get Leaderboard
  static Future<List<dynamic>> getLeaderboard() async {
    final url = Uri.parse('$baseUrl/leaderboard');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load leaderboard');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Join Challenge
  static Future<void> joinChallenge(String userId, String challengeId) async {
    final url = Uri.parse('$baseUrl/challenges/join');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'challengeId': challengeId}),
      );

      if (response.statusCode != 200) {
         final data = jsonDecode(response.body);
         throw Exception(data['message'] ?? 'Failed to join challenge');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}
