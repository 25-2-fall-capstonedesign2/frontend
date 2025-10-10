import 'dart:async'; // Timer를 사용하기 위해 import
import 'package:anycall/screens/login_screen.dart';
import 'package:flutter/material.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {

  @override
  void initState() {
    super.initState();
    // 2초 후에 _navigateToLogin 함수를 실행
    Timer(const Duration(seconds: 2), _navigateToLogin);
  }

  // 로그인 화면으로 이동하는 함수
  void _navigateToLogin() {
    // pushReplacement를 사용해 스플래시 화면으로 다시 돌아올 수 없도록 함
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 화면 전체를 채우는 박스
        decoration: const BoxDecoration(
          // start_screen.png 이미지를 배경으로 설정
          image: DecorationImage(
            image: AssetImage('assets/images/start_screen.png'),
            fit: BoxFit.cover, // 이미지가 화면에 꽉 차도록 설정
          ),
        ),
      ),
    );
  }
}