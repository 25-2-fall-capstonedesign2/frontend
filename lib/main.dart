// lib/main.dart

import 'dart:io'; // Platform을 확인하기 위해 import
import 'package:anycall/screens/start_screen.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart'; // 방금 추가한 패키지 import

// main 함수를 async로 변경합니다.
void main() async {
  // runApp을 실행하기 전에 위젯 바인딩을 초기화합니다.
  WidgetsFlutterBinding.ensureInitialized();

  // 현재 플랫폼이 macOS인지 확인합니다.
  if (Platform.isMacOS) {
    // window_manager를 초기화합니다.
    await windowManager.ensureInitialized();

    // 창에 적용할 옵션을 설정합니다.
    WindowOptions windowOptions = const WindowOptions(
      size: Size(450, 800),      // 시작 시 창 크기 (모바일과 유사하게)
      center: true,               // 창을 화면 중앙에 위치
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    // 설정한 옵션으로 창이 나타날 때까지 기다립니다.
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // 화면 비율을 9:16 정도로 고정합니다.
      await windowManager.setAspectRatio(9 / 16);
    });
  }

  // 앱을 실행합니다.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anycall',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: const StartScreen(),
    );
  }
}