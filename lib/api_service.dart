// lib/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anycall/models/voice_profile.dart';
import 'package:anycall/models/chat_message.dart';

class ApiService {
  // 서버 주소 (HTTPS로 변경, 표준 포트 443 사용)
  static const String _baseUrl = 'https://anycall.store';
  // static const _storage = FlutterSecureStorage(); // <-- 제거

  // --- SSL 인증서 검증을 무시하는 HTTP Client 생성 (동일) ---
  static http.Client createInsecureHttpClient() {
    final client = HttpClient()
      ..badCertificateCallback =
      ((X509Certificate cert, String host, int port) => true);
    return IOClient(client);
  }

  // --- 토큰 관리 (shared_preferences 사용) ---
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // [DisplayName 관련 함수 제거되었으므로, logout 함수도 수정합니다.]
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_name'); // 혹시 모를 잔여 데이터 삭제
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
        await _saveToken(token); // shared_preferences 함수 사용
        return {'success': true};
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

  // --- 6. 통화 시작 API ---
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

      print('통화 시작 상태 코드: ${response.statusCode}');

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

  // --- 7. 통화 종료 API ---
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

  // --- 8. 통화 대상 목록 조회 API ---
  static Future<List<VoiceProfile>> getVoiceProfiles() async {
    final client = createInsecureHttpClient();
    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/api/voice-profiles/me'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => VoiceProfile.fromJson(json)).toList();
      } else {
        print('목소리 목록 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('목소리 목록 조회 오류: $e');
      return [];
    } finally {
      client.close();
    }
  }

  // --- 9. 대화 기록 조회 API ---
  static Future<List<ChatMessage>> getMessages(String profileName) async {
    final client = createInsecureHttpClient();
    try {
      // 쿼리 파라미터 생성
      final uri = Uri.parse('$_baseUrl/api/v1/history/messages')
          .replace(queryParameters: {'profileName': profileName});

      final response = await client.get(
        uri,
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        print('메시지 내역 조회 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('메시지 내역 조회 오류: $e');
      return [];
    } finally {
      client.close();
    }
  }
}