import 'package:anycall/screens/home_screen.dart';
import 'package:anycall/screens/terms_screen.dart';
import 'package:anycall/screens/privacy_policy_screen.dart';
import 'package:flutter/material.dart';
// import 'package:anycall/common/app_colors.dart'; // 색상 파일이 있다면 사용

// 1. StatefulWidget으로 변경
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 2. 전화번호와 비밀번호 입력값을 가져오기 위한 컨트롤러 선언
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    // 위젯이 사라질 때 컨트롤러 정리
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 3. 로그인 실패 팝업을 띄우는 함수
  void _showLoginFailedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그인 실패'),
          content: const Text('전화번호와 비밀번호를 모두 입력해주세요.'),
          actions: <Widget>[
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(context).pop(); // 팝업 닫기
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.background,
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              const Text(
                'AI 전화',
                style: TextStyle(
                  // color: AppColors.textPrimary,
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '인공지능과 실시간 음성 대화하는 플랫폼',
                style: TextStyle(
                  // color: AppColors.textSecondary,
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 60),

              // 4. 전화번호 입력 필드에 컨트롤러 연결
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: '전화번호',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // 5. 비밀번호 입력 필드에 컨트롤러 연결
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  labelStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const Spacer(),

              // 6. 로그인 버튼 로직 수정
              ElevatedButton(
                onPressed: () {
                  // 입력값이 비어있는지 확인
                  if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
                    // 비어있다면 팝업 띄우기
                    _showLoginFailedDialog();
                  } else {
                    // 비어있지 않다면 홈 화면으로 이동
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // AppColors.primary
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('로그인'),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // 버튼들을 중앙에 배치
                children: [
                  // 이용약관 버튼
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
                        color: Colors.grey,
                        fontSize: 12, // 폰트 크기 약간 줄임
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  // 버튼 사이의 구분선
                  const Text(
                    ' | ',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),

                  // 개인정보처리방침 버튼
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
                        color: Colors.grey,
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
    );
  }
}