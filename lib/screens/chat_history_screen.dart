// lib/screens/chat_history_screen.dart

import 'package:flutter/material.dart';
import 'package:anycall/api_service.dart';
import 'package:anycall/models/chat_message.dart';

class ChatHistoryScreen extends StatefulWidget {
  final String friendName; // 백엔드의 'profileName'에 해당

  const ChatHistoryScreen({super.key, required this.friendName});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  late Future<List<ChatMessage>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    // API 호출 (friendName을 profileName 파라미터로 전달)
    _messagesFuture = ApiService.getMessages(widget.friendName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.friendName}님과의 대화")),
      body: FutureBuilder<List<ChatMessage>>(
        future: _messagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("오류 발생: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("대화 기록이 없습니다."));
          }

          final messages = snapshot.data!;
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isMe = msg.sender == "USER"; // 보낸 사람이 나인지 확인

              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg.content, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(msg.timestamp, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}