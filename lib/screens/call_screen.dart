import 'package:flutter/material.dart';

class CallScreen extends StatelessWidget {
  // 1. 통화할 친구의 이름을 저장할 변수 추가
  final String friendName;

  // 2. 생성자를 통해 친구 이름을 전달받도록 수정
  const CallScreen({
    super.key,
    required this.friendName, // required 키워드로 필수값으로 지정
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),

              // 3. 고정된 이름 대신 전달받은 friendName 변수 사용
              Text(
                friendName,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              const Text(
                '연결 중...',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.mic_off, color: Colors.white, size: 30),
                  ),
                  IconButton(
                    onPressed: () {
                      // 통화 종료 시 현재 화면을 닫고 이전 화면으로 돌아감
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.call_end, color: Colors.white, size: 40),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.all(15)
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.volume_up, color: Colors.white, size: 30),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}