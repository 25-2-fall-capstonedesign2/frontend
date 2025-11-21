// lib/screens/login_screen.dart

import 'package:anycall/screens/home_screen.dart';
import 'package:anycall/screens/terms_screen.dart';
import 'package:anycall/screens/privacy_policy_screen.dart';
import 'package:anycall/screens/signup_screen.dart';
import 'package:anycall/screens/intro_screen.dart';
import 'package:anycall/api_service.dart'; // ApiService import
import 'package:flutter/material.dart';
import 'dart:io';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- phone 으로 컨트롤러 수정 ---
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // 로딩 상태

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 2. 팝업 함수
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그인 실패'),
          content: Text(message), // 서버에서 받은 메시지 표시
          actions: <Widget>[
            TextButton(
              child: const Text('확인'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // --- 3. 로그인 버튼 API 연동 로직 ---
  void _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showErrorDialog('전화번호와 비밀번호를 모두 입력해주세요.');
      return;
    }

    setState(() { _isLoading = true; });

    final result = await ApiService.login(
      phone,
      password,
    );

    setState(() { _isLoading = false; });

    if (!mounted) return; // 화면이 사라진 경우 중단

    if (result['success'] == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const IntroScreen()),
      );
    } else {
      // API 명세서의 401 Unauthorized 메시지
      _showErrorDialog(result['message'] ?? '로그인에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_screen.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // --- 4. '이메일' 필드를 '전화번호'로 수정 ---
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: '전화번호', // UI 텍스트 변경
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.black,
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone, // 키보드 타입 변경
                  ),
                  const SizedBox(height: 20),

                  // 4. 비밀번호 입력 필드 (변경 없음)
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.black,
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 40),

                  // 5. 로그인 버튼
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin, // API 연동
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      '로그인',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // 6. 회원가입 버튼
                  const SizedBox(height: 16),
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupScreen()),
                        );
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),

                      child: const Text(
                        '회원가입',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // 7. 종료 버튼 추가 및 약관 링크 위로 Spacer 이동
                  FractionallySizedBox(
                    widthFactor: 0.4, // 너비 40%
                    child: ElevatedButton(
                      onPressed: () {
                        exit(0); // 앱 종료 기능
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('종료', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 8. 약관 버튼들
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TermsScreen()),
                          );
                        },

                        child: const Text(
                          '이용약관',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),

                      const Text(
                        ' | ',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                          );
                        },

                        child: const Text(
                          '개인정보처리방침',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}