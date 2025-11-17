// lib/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // 1. 서버 주소를 백엔드팀이 알려준 Public DNS로 변경 (HTTP로 가정)
  // (ec2-3-104-116-91.ap-southeast-2.compute.amazonaws.com)
  static const String _baseUrl = 'http://ec2-3-104-116-91.ap-southeast-2.compute.amazonaws.com:8080';
  static const _storage = FlutterSecureStorage();

  // --- 토큰 관리 ---
  static Future<void> _saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    String? token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- 2. 회원가입 API ---
  static Future<Map<String, dynamic>> signup(String phoneNumber, String password, String displayName) async {
    try {
      final response = await http.post(
          Uri.parse('$_baseUrl/api/auth/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
      'phoneNumber': phoneNumber,
      'password': password,
      'displayName': displayName,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
    return {'success': true, 'message': body['message']};
    } else {
    return {'success': false, 'message': body['message'] ?? '회원가입에 실패했습니다.'};
    }
    } catch (e) {
    print('회원가입 실패: $e');
    return {'success': false, 'message': '서버에 연결할 수 없습니다.'};
    }
  }

  // --- 3. 로그인 API (필드 이름 수정) ---
  static Future<Map<String, dynamic>> login(String phoneNumber, String password) async {
    try {
      final response = await http.post(
          Uri.parse('$_baseUrl/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
      'phoneNumber': phoneNumber, // API 명세서 기준 'phoneNumber'
      'password': password,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
    String token = body['token'];
    await _saveToken(token);
    return {'success': true};
    } else {
    return {'success': false, 'message': body['message'] ?? '로그인에 실패했습니다.'};
    }
    } catch (e) {
    print('로그인 실패: $e');
    return {'success': false, 'message': '서버에 연결할 수 없습니다.'};
    }
  }

  // --- 4. 통화 시작 API (파라미터 및 Body 추가) ---
  static Future<String?> startCall(String participantName) async {
    try {
      final response = await http.post(
          Uri.parse('$_baseUrl/api/calls/start'),
          headers: await _getAuthHeaders(),
    body: jsonEncode({ // API 명세서에 따라 participantName을 body에 추가
    'participantName': participantName
    }),
    );

    if (response.statusCode == 200) {
    // 명세서의 callSessionId를 파싱 (테스트 HTML은 callSessionId)
    String sessionId = jsonDecode(response.body)['callSessionId'].toString();
    return sessionId;
    } else {
    return null;
    }
    } catch (e) {
    print('통화 시작 실패: $e');
    return null;
    }
  }

  // --- 5. 통화 종료 API ---
  static Future<void> hangUp(String sessionId) async {
    try {
      await http.post(
          Uri.parse('$_baseUrl/api/calls/$sessionId/hangup'),
          headers: await _getAuthHeaders(),
    );
    } catch (e) {
    print('통화 종료 실패: $e');
    }
  }

  // --- 6. (신규) 내 프로필 정보 조회 API ---
  // (백엔드에 GET /api/auth/me 가 구현되어 있다고 가정합니다)
  static Future<String?> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/me'), // <-- 이 엔드포인트가 필요합니다
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        // 서버 응답이 {"displayName": "홍길동"} 형태라고 가정
        // UTF-8로 디코딩
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return body['displayName'];
      } else {
        return null;
      }
    }
    catch (e) {
      print('프로필 조회 실패: $e');
      return null;
    }
  }

  // --- 6. 통화 대상 목록 조회 API ---
  static Future<List<String>> getParticipants() async {
    try {
      final response = await http.get(
          Uri.parse('$_baseUrl/api/v1/history/participants'),
          headers: await _getAuthHeaders(),
    );
    if (response.statusCode == 200) {
    // UTF-8로 디코딩
    List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<String>();
    } else {
    return [];
    }
    } catch (e) {
    print('통화 대상 목록 조회 실패: $e');
    return [];
    }
  }

  // --- 7. 메시지 내역 조회 API ---
  static Future<List<Map<String, dynamic>>> getMessages(String participantName) async {
    try {
      final response = await http.get(
          Uri.parse('$_baseUrl/api/v1/history/messages?participantName=$participantName'),
          headers: await _getAuthHeaders(),
    );
    if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.cast<Map<String, dynamic>>();
    } else {
    return [];
    }
    } catch (e) {
    print('메시지 내역 조회 실패: $e');
    return [];
    }
  }
}