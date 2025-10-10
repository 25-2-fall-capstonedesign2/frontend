import 'package:anycall/screens/home_screen.dart'; // Friend 클래스를 사용하기 위해 import
import 'package:flutter/material.dart';

class ChatHistoryScreen extends StatelessWidget {
  // 어떤 친구의 대화 기록인지 받기 위해 Friend 객체를 전달받음
  final Friend friend;

  const ChatHistoryScreen({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${friend.name}님과의 대화'), // 앱 바 제목에 친구 이름 표시
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: friend.chatHistory.length, // 대화 기록 개수만큼 목록 생성
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(friend.chatHistory[index]), // 각 대화 내용을 텍스트로 표시
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          );
        },
      ),
    );
  }
}