// lib/screens/home_screen.dart

import 'package:anycall/screens/login_screen.dart';
import 'package:anycall/screens/call_screen.dart';
import 'package:anycall/screens/chat_history_screen.dart';
import 'package:anycall/api_service.dart';
import 'package:flutter/material.dart';

// Friend 클래스
class Friend {
  final String name;
  final String status;
  final Color statusColor;
  final String lastSeen;
  final List<String> chatHistory;

  Friend({
    required this.name,
    required this.status,
    required this.statusColor,
    required this.lastSeen,
    required this.chatHistory,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 2. 사용자 이름과 로딩 상태를 위한 변수 추가
  String _userName = "";
  bool _isProfileLoading = true;

  // 3. 친구 목록은 우선 기존 하드코딩된 데이터를 유지
  final List<Friend> _allFriends = [
    Friend(
      name: '원영', status: '온라인', statusColor: Colors.green, lastSeen: '마지막 접속: 방금 전',
      chatHistory: ['오늘 날씨 진짜 좋다!', '응, 어디 놀러가고 싶다.'],
    ),
    Friend(
      name: '이안', status: '바쁨', statusColor: Colors.red, lastSeen: '마지막 접속: 5분 전',
      chatHistory: ['혹시 그 자료 받았어?', '아니, 아직 못 받았어. 확인해볼게.'],
    ),
    Friend(
      name: '도영', status: '자리비움', statusColor: Colors.orange, lastSeen: '마지막 접속: 1시간 전',
      chatHistory: ['점심 먹었어?'],
    ),
    Friend(
      name: '휴', status: '오프라인', statusColor: Colors.grey, lastSeen: '마지막 접속: 어제',
      chatHistory: ['어제 고마웠어!'],
    ),
  ];

  List<Friend> _filteredFriends = [];

  @override
  void initState() {
    super.initState();
    // 4. 친구 목록 로드 (기존) + 사용자 프로필 로드 (신규)
    _filteredFriends = _allFriends;
    _searchController.addListener(_filterFriends);
    _loadUserProfile(); // <-- 사용자 이름 불러오기
  }

  // 5. 사용자 프로필을 불러오는 함수
  Future<void> _loadUserProfile() async {
    // String? userName = await ApiService.getUserProfile();
    if (mounted) { // 화면이 사라지지 않았다면
      setState(() {
        _userName = "사용자"; // 이름이 없으면 "사용자"
        _isProfileLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 검색 필터 함수
  void _filterFriends() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFriends = _allFriends;
      } else {
        _filteredFriends = _allFriends
            .where((friend) => friend.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( /* ... (AppBar 변경 없음) ... */ ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- 6. 환영 문구 추가 ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: _isProfileLoading
                ? const Center(child: CircularProgressIndicator()) // 로딩 중
                : Text(
              '$_userName님, 안녕하세요?',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 10), // 환영 문구와 검색창 사이 간격
          // ----------------------

          // 검색창
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: '친구 검색',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // '나' 타일
          _buildFriendTile(
            context: context,
            friend: Friend(
              name: '나',
              status: '온라인',
              statusColor: Colors.green,
              lastSeen: 'AI와 대화할 준비가 되었습니다',
              chatHistory: [],
            ),
            isMe: true,
          ),
          const Divider(),
          const SizedBox(height: 20),
          Text(
            '가상 통화 목록 (${_filteredFriends.length})',
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // 친구 목록
          ..._filteredFriends.map((friend) => _buildFriendTile(
            context: context,
            friend: friend,
          )),
        ],
      ),
    );
  }

  Widget _buildFriendTile({
    required BuildContext context,
    required Friend friend,
    bool isMe = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
      leading: Stack(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: friend.statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          )
        ],
      ),
      title: Row(
        children: [
          Text(friend.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(width: 8),
          Text(friend.status, style: TextStyle(color: friend.statusColor, fontSize: 14)),
        ],
      ),
      subtitle: Text(friend.lastSeen, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: isMe
          ? null
          : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatHistoryScreen(friend: friend),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
          ),
          IconButton(
            onPressed: () async {
              // 7. 통화 시작 API (participantName 전달)
              String? sessionId = await ApiService.startCall(friend.name);

              if (sessionId != null) {
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallScreen(
                      friendName: friend.name,
                      sessionId: sessionId,
                    ),
                  ),
                );
              } else {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('통화 서버에 연결할 수 없습니다.')),
                );
              }
            },
            icon: const Icon(Icons.call_outlined, color: Colors.green),
          ),
        ],
      ),
    );
  }
}