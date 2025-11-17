import 'package:anycall/screens/login_screen.dart';
import 'package:anycall/screens/call_screen.dart';
import 'package:anycall/screens/chat_history_screen.dart';
import 'package:flutter/material.dart';

// 1. 친구 데이터를 관리하기 위한 클래스
class Friend {
  final String name;
  final String status;
  final Color statusColor;
  final String lastSeen;
  final List<String> chatHistory; // 대화 기록 리스트

  Friend({
    required this.name,
    required this.status,
    required this.statusColor,
    required this.lastSeen,
    required this.chatHistory, // 생성자에 추가
  });
}

// 2. StatefulWidget으로 변경
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 3. 전체 친구 목록 (대화 기록 데이터 포함)
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

  // 화면에 보여줄 필터링된 친구 목록
  List<Friend> _filteredFriends = [];

  @override
  void initState() {
    super.initState();
    _filteredFriends = _allFriends;
    _searchController.addListener(_filterFriends);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 검색어에 따라 친구 목록을 필터링하는 함수
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text('AI 전화', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
        leadingWidth: 100,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
          IconButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
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

          // '나' 타일은 Friend 객체를 직접 만들어서 전달
          _buildFriendTile(
            context: context,
            friend: Friend(
              name: '나',
              status: '온라인',
              statusColor: Colors.green,
              lastSeen: 'AI와 대화할 준비가 되었습니다',
              chatHistory: [], // '나'는 대화 기록 없음
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

          // .map() 에서 friend 객체 전체를 _buildFriendTile로 전달
          ..._filteredFriends.map((friend) => _buildFriendTile(
            context: context,
            friend: friend,
          )),
        ],
      ),
    );
  }

  // Friend 객체를 통째로 받도록 수정된 함수
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
              // ChatHistoryScreen으로 이동하며 friend 객체 전달
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
            onPressed: () {
              // CallScreen으로 이동하며 친구 이름 전달
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallScreen(friendName: friend.name),
                ),
              );
            },
            icon: const Icon(Icons.call_outlined, color: Colors.green),
          ),
        ],
      ),
    );
  }
}