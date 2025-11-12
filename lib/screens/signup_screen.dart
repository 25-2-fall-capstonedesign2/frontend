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

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 로그인 화면과 비슷한 테마로 배경색 지정
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
              // 전화번호 필드 (API 명세 기준)
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: '전화번호',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // 비밀번호 필드
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),

              // 이름(DisplayName) 필드
              TextField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: '이름 (표시용)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white70)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 40),

              // 회원가입 완료 버튼
              ElevatedButton(
                onPressed: () {
                  // TODO: 여기에 실제 회원가입 API 로직을 구현합니다.
                  // 지금은 데모이므로, 성공 시 로그인 화면으로 돌아갑니다.
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                child: const Text('회원가입 완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}