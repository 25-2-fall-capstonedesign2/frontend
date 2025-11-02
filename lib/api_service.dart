import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  //********* 실제 서버 주소로 변경하기! *********//
  static const String _baseUrl = 'http://localhost:8080';
  static const _storage = FlutterSecureStorage();

  // 토큰을 안전하게 저장
  static Future<void> _saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  // 저장된 토큰 읽기
  static Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // 인증 헤더 생성
  static Future<Map<String, String>> _getAuthHeaders() async {
    String? token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. 로그인 API
  static Future<bool> login(String phone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        String token = jsonDecode(response.body)['token'];
        await _saveToken(token);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('로그인 실패: $e');
      return false;
    }
  }

  // 2. 통화 시작 API (sessionId 반환)
  static Future<String?> startCall() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/calls/start'),
        headers: await _getAuthHeaders(), // 인증 헤더 사용
      );

      if (response.statusCode == 200) {
        // 응답 본문에서 sessionId를 파싱 (백엔드 응답 형식에 맞춰야 함)
        // 예시: { "sessionId": "4" }
        String sessionId = jsonDecode(response.body)['sessionId'].toString();
        return sessionId;
      } else {
        return null;
      }
    } catch (e) {
      print('통화 시작 실패: $e');
      return null;
    }
  }

  // 3. 통화 종료 API
  static Future<void> hangUp(String sessionId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/calls/$sessionId/hangup'),
        headers: await _getAuthHeaders(), // 인증 헤더 사용
      );
    } catch (e) {
      print('통화 종료 실패: $e');
    }
  }
}