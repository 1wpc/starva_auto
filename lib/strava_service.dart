import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secrets.dart';

class StravaService {
  // Singleton pattern
  static final StravaService _instance = StravaService._internal();
  factory StravaService() => _instance;
  StravaService._internal();

  static const String _authUrl = 'https://www.strava.com/oauth/authorize';
  static const String _tokenUrl = 'https://www.strava.com/oauth/token';
  static const String _uploadUrl = 'https://www.strava.com/api/v3/uploads';
  static const String _redirectUri = 'starvaauto://localhost';
  
  final _storage = const FlutterSecureStorage();

  String? _customClientId;
  String? _customClientSecret;

  String get clientId => (_customClientId != null && _customClientId!.isNotEmpty) ? _customClientId! : AppSecrets.clientId;
  String get clientSecret => (_customClientSecret != null && _customClientSecret!.isNotEmpty) ? _customClientSecret! : AppSecrets.clientSecret;
  
  String? accessToken;
  String? refreshToken;
  int? expiresAt;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('access_token');
    refreshToken = prefs.getString('refresh_token');
    expiresAt = prefs.getInt('expires_at');
    
    _customClientId = await _storage.read(key: 'strava_custom_client_id');
    _customClientSecret = await _storage.read(key: 'strava_custom_client_secret');
  }
  
  Future<void> saveCustomCredentials(String id, String secret) async {
    await _storage.write(key: 'strava_custom_client_id', value: id.trim());
    await _storage.write(key: 'strava_custom_client_secret', value: secret.trim());
    _customClientId = id.trim();
    _customClientSecret = secret.trim();
    
    // Clear tokens to force re-auth with new credentials
    await logout();
  }
  
  Future<void> clearCustomCredentials() async {
    await _storage.delete(key: 'strava_custom_client_id');
    await _storage.delete(key: 'strava_custom_client_secret');
    _customClientId = null;
    _customClientSecret = null;
    
    // Clear tokens to force re-auth
    await logout();
  }
  
  bool get hasCustomCredentials => _customClientId != null && _customClientId!.isNotEmpty && _customClientSecret != null && _customClientSecret!.isNotEmpty;

  bool get isAuthenticated {
    if (accessToken == null || expiresAt == null) return false;
    // 如果过期了，认为还是“认证”过的，但在请求时会刷新
    return true; 
  }

  bool get hasCredentials => clientId != 'YOUR_CLIENT_ID' && clientSecret != 'YOUR_CLIENT_SECRET';

  Uri getAuthorizationUrl() {
    if (!hasCredentials) throw Exception('Client ID/Secret not configured in secrets.dart');
    return Uri.parse(
        '$_authUrl?client_id=$clientId&response_type=code&redirect_uri=$_redirectUri&approval_prompt=force&scope=activity:write');
  }

  Future<bool> handleAuthCallback(String url) async {
    final uri = Uri.parse(url);
    if (uri.queryParameters.containsKey('error')) {
      throw Exception('Auth error: ${uri.queryParameters['error']}');
    }
    if (uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['code'];
      return await _exchangeToken(code!);
    }
    return false;
  }

  Future<bool> _exchangeToken(String code) async {
    final response = await http.post(Uri.parse(_tokenUrl), body: {
      'client_id': clientId,
      'client_secret': clientSecret,
      'code': code,
      'grant_type': 'authorization_code',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveTokens(data);
      return true;
    } else {
      throw Exception('Token exchange failed: ${response.body}');
    }
  }

  Future<void> _refreshToken() async {
    if (refreshToken == null) throw Exception('No refresh token');
    final response = await http.post(Uri.parse(_tokenUrl), body: {
      'client_id': clientId,
      'client_secret': clientSecret,
      'refresh_token': refreshToken,
      'grant_type': 'refresh_token',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveTokens(data);
    } else {
       // Token refresh failed, maybe logout?
       throw Exception('Failed to refresh token');
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    accessToken = data['access_token'];
    refreshToken = data['refresh_token'];
    expiresAt = data['expires_at'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken!);
    await prefs.setString('refresh_token', refreshToken!);
    await prefs.setInt('expires_at', expiresAt!);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('expires_at');
    accessToken = null;
    refreshToken = null;
    expiresAt = null;
  }

  Future<String> uploadFitFile(File file) async {
    if (!isAuthenticated) throw Exception('Not authenticated');

    // Check expiration
    if (DateTime.now().millisecondsSinceEpoch / 1000 > expiresAt!) {
      await _refreshToken();
    }

    var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
    request.headers['Authorization'] = 'Bearer $accessToken';
    
    // Read file bytes directly to avoid path permission issues
    final fileBytes = await file.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: file.path.split('/').last,
    ));
    
    request.fields['data_type'] = 'fit';

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return 'Upload successful! Upload ID: ${data['id']}';
    } else {
      // Strava might return 409 for duplicate activity
      final data = jsonDecode(response.body);
      if (data['error'] != null) {
        throw Exception('Upload failed: ${data['error']}');
      } else if (data['message'] != null) {
         throw Exception('Upload failed: ${data['message']}');
      }
      throw Exception('Upload failed with status ${response.statusCode}');
    }
  }
}
