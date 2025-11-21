// lib/screens/intro_screen.dart

import 'package:anycall/screens/home_screen.dart';
import 'package:flutter/material.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 배경색: 0xFF0A1740
    const Color backgroundColor = Color(0xFF0A1740);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // 배경과 동일하게 투명하게
        elevation: 0,
        automaticallyImplyLeading: false, // 뒤로가기 버튼 숨김
        actions: [
          // 우상단 설정 아이콘
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 28),
            onPressed: () {
              // TODO: 설정 화면으로 이동 로직 추가
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true, // body가 appBar 영역까지 침범하도록 설정
      body: SafeArea(
        top: false, // AppBar 때문에 SafeArea 상단 영역은 무시
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            children: [
              const Spacer(flex: 9), // 상단 공간 확보

              // 1. 주요 문구
              const Text(
                '그리운 목소리와\n다시 한번.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // 2. 보조 문구
              const Text(
                '소중한 사람의 목소리로\n마음을 나누고 추억을 되새겨보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFC8C8C8), // 밝은 회색
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 6), // 중앙과 하단 버튼 사이의 넓은 공간

              // 3. 통화 시작 버튼
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 홈 화면으로 이동
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  },
                  icon: const Icon(Icons.call_outlined, color: Colors.black),
                  label: const Text(
                    '통화 시작',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // 흰색 배경
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}