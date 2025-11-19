// lib/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // 서버 주소 (HTTPS로 변경, 표준 포트 443 사용)
  static const String _baseUrl = 'https://anycall.store';
  static const _storage = FlutterSecureStorage();

  // --- SSL 인증서 검증을 무시하는 HTTP Client 생성 ---
  static http.Client createInsecureHttpClient() {
    final client = HttpClient()
      ..badCertificateCallback =
      ((X509Certificate cert, String host, int port) => true); // 항상 true 반환하여 인증서 무시
    return IOClient(client);
  }

  // --- 토큰 관리 ---
  static Future<void> _saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // --- (DisplayName 저장 함수 제거) ---

  // 로그아웃은 토큰만 제거
  static Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_name'); // 기존에 user_name도 삭제하던 코드는 유지
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    String? token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- 4. 회원가입 API ---
  static Future<Map<String, dynamic>> signup(String phone, String password, String displayName) async {
    final client = createInsecureHttpClient();

    print('>>> [API_CALL] 회원가입 요청 데이터: ${jsonEncode({
      'phone': phone,
      'password': password,
      'displayName': displayName,
    })}');

    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
          'displayName': displayName,
        }),
      );

      print("Raw Response Body: '${response.body}'");
      final body = jsonDecode(response.body);
      print('회원가입 요청 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      } else {
        return {'success': false, 'message': body['message'] ?? '회원가입에 실패했습니다.'};
      }
    } catch (e) {
      print('회원가입 실패 - 발생한 오류: ${e.runtimeType}');
      print('회원가입 실패 - 상세 내용: $e');
      return {'success': false, 'message': '서버 응답 형식이 올바르지 않거나 연결 오류입니다.'};
    } finally {
      client.close();
    }
  }

  // --- 5. 로그인 API (토큰만 저장) ---
  static Future<Map<String, dynamic>> login(String phone, String password) async {
    final client = createInsecureHttpClient();

    print('>>> [API_CALL] 로그인 요청 데이터: ${jsonEncode({
      'phone': phone,
      'password': password,
    })}');

    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      final body = jsonDecode(response.body);
      print('로그인 요청 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        String token = body['token'];

        // print('>>> [DEBUG] 로그인 성공 - 수신된 JWT 토큰: $token');

        await _saveToken(token); // 토큰만 저장
        // displayName 로직 제거
        return {'success': true}; // 토큰 저장 후 성공만 반환
      } else {
        return {'success': false, 'message': body['message'] ?? '로그인에 실패했습니다.'};
      }
    } catch (e) {
      print('로그인 연결 오류: $e');
      return {'success': false, 'message': '서버에 연결할 수 없습니다. (인증서 문제 또는 시간 초과)'};
    } finally {
      client.close();
    }
  }

  // --- 6. 통화 시작 API (변경 없음) ---
  static Future<String?> startCall(String participantName) async {
    final client = createInsecureHttpClient();
    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/api/calls/start'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'participantName': participantName
        }),
      );
      if (response.statusCode == 200) {
        String sessionId = jsonDecode(response.body)['callSessionId'].toString();
        return sessionId;
      } else {
        return null;
      }
    } catch (e) {
      print('통화 시작 오류: $e');
      return null;
    } finally {
      client.close();
    }
  }

  // --- 7. 통화 종료 API (변경 없음) ---
  static Future<void> hangUp(String sessionId) async {
    final client = createInsecureHttpClient();
    try {
      await client.post(
        Uri.parse('$_baseUrl/api/calls/$sessionId/hangup'),
        headers: await _getAuthHeaders(),
      );
    } catch (e) {
      print('통화 종료 실패: $e');
    } finally {
      client.close();
    }
  }

  // --- 8. 프로필 조회 API (제거됨 - 미지원 기능) ---

  // --- 9. 통화 대상 목록 조회 API (변경 없음) ---
  static Future<List<String>> getParticipants() async {
    final client = createInsecureHttpClient();
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/api/v1/history/participants'),
        headers: await _getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<String>();
      } else {
        return [];
      }
    } catch (e) {
      print('통화 대상 목록 조회 실패: $e');
      return [];
    } finally {
      client.close();
    }
  }

  // --- 10. 메시지 내역 조회 API (변경 없음) ---
  static Future<List<Map<String, dynamic>>> getMessages(String participantName) async {
    final client = createInsecureHttpClient();
    try {
      final response = await client.get(
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
    } finally {
      client.close();
    }
  }
}