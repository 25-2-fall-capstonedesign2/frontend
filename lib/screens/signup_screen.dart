// lib/screens/signup_screen.dart

import 'package:anycall/api_service.dart'; // 1. ApiService import
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false; // 로딩 상태

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  // --- 2. 회원가입 API 연동 로직 ---
  void _handleSignup() async {
    final phone = _phoneController.text;
    final password = _passwordController.text;
    final displayName = _displayNameController.text;

    // 1. 필수 항목 누락 검사
    if (phone.isEmpty || password.isEmpty || displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 입력해주세요.')),
      );
      return;
    }

    // 2-1. 전화번호 형식 검사 (010으로 시작하는 11자리 숫자)
    final phoneRegex = RegExp(r'^010\d{8}$'); // 010 + 8자리 숫자 = 11자리
    if (!phoneRegex.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화번호 형식이 올바르지 않습니다. (010으로 시작하는 11자리 숫자)')),
      );
      return;
    }

    // 2-2. 비밀번호 길이 검사 (8자리 이상)
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 최소 8자리 이상이어야 합니다.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final result = await ApiService.signup(phone, password, displayName);

    setState(() { _isLoading = false; });

    if (!mounted) return;

    if (result['success'] == true) {
      // 회원가입 성공 시
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '회원가입 성공!')),
      );
      Navigator.of(context).pop(); // 로그인 화면으로 돌아가기
    } else {
      // 회원가입 실패 시 (예: "이미 사용 중인 전화번호입니다.")
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? '회원가입 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1740),
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: Colors.transparent, // 배경과 어우러지도록 투명하게
        elevation: 0, // 그림자 제거
        foregroundColor: Colors.white, // 아이콘 및 텍스트 흰색으로
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: '전화번호',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.black,
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.black,
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: '사용자 이름',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.black,
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 40),

              // --- 3. 회원가입 완료 버튼 수정 ---
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup, // API 연동
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  '회원가입 완료',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}