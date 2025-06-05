import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../screens/missions.dart';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';



class ApiService {
  static const String baseUrl = "http://192.168.1.17:3000"; // Your backend URL


  // ✅ Fetch User Data (Requires Token)
  static Future<Map<String, dynamic>> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    print("📤 Token used in Authorization header: Bearer $token");

    if (token.isEmpty) {

      throw Exception("User not authenticated. No token found.");
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error: ${response.statusCode} - ${response.body}");
    }
  }

  // ✅ Register User
  static Future<Map<String, dynamic>> registerUser(
      String username, String email, String phone, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "phone": phone,
        "password": password,
        "role": role
      }),
    );

    return await _handleResponse(response); // Ensures correct return type
  }

  // ✅ Login User & Store Token
  static Future<Map<String, dynamic>> loginUser(String emailOrPhone, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": emailOrPhone,
        "phone": emailOrPhone,
        "password": password
      }),
    );
    print("Login Response: ${response.body}"); // Debugging
    final responseData = await _handleResponse(response);

    if (responseData.containsKey("accessToken")) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseData["accessToken"] ?? "");
      await prefs.setString('refreshToken', responseData["refreshToken"] ?? "");
      await prefs.setString('role', responseData["role"] ?? "");

      print("✅ ACCESS TOKEN SAVED: ${responseData["accessToken"]}");
      print("✅ REFRESH TOKEN SAVED: ${responseData["refreshToken"]}");
      print("✅ ROLE: ${responseData["role"]}");
    }


    return responseData;
  }

  //refresh token
  static Future<String> refreshAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String refreshToken = prefs.getString('refreshToken') ?? "";

    if (refreshToken.isEmpty) {
      throw Exception("No refresh token found.");
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "refreshToken": refreshToken, // ✅ use saved token
      }),
    );

    final responseData = await _handleResponse(response);

    if (responseData.containsKey('accessToken')) {
      await prefs.setString('token', responseData['accessToken']);
      return responseData['accessToken'];
    } else {
      throw Exception("Failed to refresh token.");
    }
  }


  // ✅ Fetch Data from /test Endpoint
  static Future<List<dynamic>> fetchData() async {
    final response = await http.get(Uri.parse("$baseUrl/test"));

    if (response.statusCode == 200) {  // Check for successful response
      final data = jsonDecode(response.body);

      if (data is List) { // Ensure the response is a list
        return data;
      }
      if (data is Map) {return [data];}
      else {
        throw Exception("Unexpected response format: Expected a List.");
      }
    } else {
      throw Exception("Failed to load data: ${response.body}");
    }
  }

  // ✅ Fetch Staff List
  static Future<List<dynamic>> fetchStaffList() async {
    final response = await http.get(Uri.parse("$baseUrl/staff"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['staff'] ?? []; // Adjust based on your actual API response
    } else {
      throw Exception("Error fetching staff list: ${response.statusCode}");
    }
  }


  // ✅ Fetch Assigned Locations
  static Future<void> fetchLocations() async {
    final response = await http.get(Uri.parse("$baseUrl/staff/locations"));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      print("Locations: $data");
    } else {
      print("Error fetching locations: ${response.statusCode}");
    }
  }


  // ✅ Submit Visit (Photo + Remark)
  static Future<void> submitVisit({
    required String staffId,
    required String location,
    required double latitude,
    required double longitude,
    required String photoBase64,
    required String remark,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/staff/visit"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "staff_id": staffId,
        "location": location,
        "latitude": latitude,
        "longitude": longitude,
        "photo": photoBase64,  // Convert image to Base64 before sending
        "remark": remark,
      }),
    );

    if (response.statusCode == 201) {
      print("Visit submitted successfully");
    } else {
      print("Error submitting visit: ${response.body}");
    }
  }

  // ✅ Unified Response Handler
  static Future<dynamic> _handleResponse(http.Response response) async {
    try {
      if (response.body.isEmpty) {
        throw Exception("Empty response from server.");
      }

      final decodedBody = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decodedBody ?? {}; // Ensure it's not null
      } else {
        throw Exception(decodedBody["message"]?.toString() ?? "Something went wrong");
      }
    } catch (e) {
      throw Exception("Unexpected error: ${response.body}");
    }
  }
  static Future<List<dynamic>> getAllStaff() async {
    final response = await http.get(Uri.parse('$baseUrl/staff'));
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final data = responseData['data'];
      if (data is List) {
        return data;
      } else {
        throw Exception("Expected a list in 'data', got: ${data.runtimeType}");
      }
    } else {
      throw Exception('Failed to load staff');
    }
  }



  // Fetch missions by staff ID
  static Future<List<dynamic>> getMissions(String staffId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/missions/$staffId'));
      print('Raw API response: ${response.body}');  // Print raw response

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Decoded data: $data');  // Print the decoded data
        if (data is List) {
          return data;
        } else {
          throw Exception("Invalid response format: Expected a List");
        }
      } else {
        throw Exception("Failed to load missions. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in API call: $e");
      rethrow;
    }
  }
  static Future<void> completeMission({
    required String missionId,
    required String staffId,
    required String remarks,
    required File photoFile,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    final uri = Uri.parse('$baseUrl/missions/complete');

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['missionId'] = missionId;
    request.fields['staffId'] = staffId;
    request.fields['remarks'] = remarks;

    // Detect mime type for image upload
    final mimeType = lookupMimeType(photoFile.path) ?? 'image/jpeg';
    final mimeSplit = mimeType.split('/');

    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        photoFile.path,
        contentType: MediaType(mimeSplit[0], mimeSplit[1]),
      ),
    );

    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("Mission completed successfully");
    } else {
      final respStr = await response.stream.bytesToString();
      print("Failed to complete mission: $respStr");
      throw Exception('Failed to complete mission, status code: ${response.statusCode}');
    }
  }

}


