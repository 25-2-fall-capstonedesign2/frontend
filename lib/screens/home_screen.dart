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
  final List<String> chatHistory; // 현재는 사용하지 않음

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

  // 2. 사용자 이름 및 로딩 상태
  String _userName = "";
  bool _isProfileLoading = true;
  bool _isFriendsLoading = true; // 친구 목록 로딩 상태 추가

  // 3. [수정] 하드코딩된 목록 대신 동적 목록으로 변경
  List<Friend> _allFriends = [];
  List<Friend> _filteredFriends = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterFriends);
    _loadData(); // 사용자 프로필과 친구 목록을 동시에 로드
  }

  // 4. 사용자 프로필 및 통화 대상 목록 API 호출
  Future<void> _loadData() async {
    // 사용자 이름을 가져오는 API (getUserProfile)는 명세에 없으므로 임시 값 사용
    String fetchedUserName = "사용자";

    // History API (1): 통화 대상 목록 조회
    List<String> participantNames = [];
    try {
      participantNames = await ApiService.getParticipants();
      // String? name = await ApiService.getUserName(); // 임시 프로필 이름 로드 (ApiService가 저장했다고 가정)
      // fetchedUserName = name ?? "사용자";
    } catch (e) {
      print("데이터 로드 중 오류 발생: $e");
    }


    if (mounted) {
      setState(() {
        _userName = fetchedUserName;

        // 서버에서 받은 이름 목록으로 Friend 객체 생성 (나머지 정보는 임시 기본값)
        _allFriends = participantNames.map((name) => Friend(
          name: name,
          status: '기록있음',
          statusColor: Colors.blueGrey, // 새로운 상태 색상
          lastSeen: '최근 기록 확인 필요',
          chatHistory: [],
        )).toList();

        _filteredFriends = _allFriends;
        _isProfileLoading = false;
        _isFriendsLoading = false;
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Center(
            child: Text('Anycall', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
      body: _isProfileLoading || _isFriendsLoading
          ? const Center(child: CircularProgressIndicator()) // 로딩 중 스피너 표시
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 환영 문구
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              // '$_userName님, 안녕하세요?', // 1단계에서 로드된 사용자명 사용
              '누구와 통화하시겠어요?',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 검색창
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: '목소리 검색',
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

          // '나' 타일 (하드코딩 유지)
          _buildFriendTile(
            context: context,
            friend: Friend(
              name: '나',
              status: '온라인',
              statusColor: Colors.green,
              lastSeen: '목소리와 통화할 준비가 되었습니다',
              chatHistory: [],
            ),
            isMe: true,
          ),
          const Divider(),
          const SizedBox(height: 20),

          // 통화 대상 목록 헤더 (API 결과 사용)
          Text(
            '목소리 목록 (${_filteredFriends.length})',
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // 친구 목록 (API 결과 사용)
          ..._filteredFriends.map((friend) => _buildFriendTile(
            context: context,
            friend: friend,
          )),
        ],
      ),
    );
  }

  // _buildFriendTile 함수 (변경 없음)
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
              // History API (2): 메시지 내역 조회
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