// lib/screens/home_screen.dart

import 'package:anycall/screens/login_screen.dart';
import 'package:anycall/screens/call_screen.dart';
import 'package:anycall/screens/chat_history_screen.dart';
import 'package:anycall/api_service.dart';
import 'package:anycall/models/voice_profile.dart';
import 'package:flutter/material.dart';
import 'package:anycall/screens/upload_voice_screen.dart';

// Friend 클래스 (UI용 데이터 모델)
class Friend {
  final int id; // [추가] 목소리 프로필 ID (통화 연결용)
  final String name;
  final String status;
  final Color statusColor;
  final String lastSeen;
  final List<String> chatHistory;

  Friend({
    required this.id, // [추가]
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

  String _userName = "";
  bool _isProfileLoading = true;
  bool _isFriendsLoading = true;

  List<Friend> _allFriends = [];
  List<Friend> _filteredFriends = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterFriends);
    _loadData();
  }

  // 데이터 로드 함수
  Future<void> _loadData() async {
    String fetchedUserName = "사용자";
    List<VoiceProfile> profiles = [];

    try {
      // 목소리 프로필 목록 조회
      profiles = await ApiService.getVoiceProfiles();

      // 사용자 이름 조회 (API가 있다면 주석 해제)
      // String? name = await ApiService.getUserName();
      // fetchedUserName = name ?? "사용자";
    } catch (e) {
      print("데이터 로드 중 오류 발생: $e");
    }

    if (mounted) {
      setState(() {
        _userName = fetchedUserName;

        // [수정] VoiceProfile 데이터를 Friend 객체로 변환 (ID 포함)
        _allFriends = profiles.map((profile) => Friend(
          id: profile.id, // [중요] ID 매핑
          name: profile.profileName,
          status: '통화가능',
          statusColor: Colors.black,
          lastSeen: '터치하여 통화 또는 채팅',
          chatHistory: [],
        )).toList();

        _filteredFriends = _allFriends;

        if (_searchController.text.isNotEmpty) {
          _filterFriends();
        }

        _isProfileLoading = false;
        _isFriendsLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        elevation: 0,
        title: const Text('Anycall', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UploadVoiceScreen()),
              );
            },
            icon: const Icon(Icons.add, size: 28), // + 아이콘
            tooltip: '목소리 추가',
          ),

          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings_outlined),
              tooltip: '환경 설정',
          ),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_outlined),
            tooltip: '로그 아웃',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _isProfileLoading || _isFriendsLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '누구와 통화하시겠어요?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: '이름 검색',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _filteredFriends.isEmpty
                  ? Center(
                child: Text(
                  _searchController.text.isEmpty
                      ? '등록된 목소리가 없습니다.'
                      : '검색 결과가 없습니다.',
                  style: const TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _filteredFriends.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return _buildFriendTile(
                    context: context,
                    friend: _filteredFriends[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendTile({
    required BuildContext context,
    required Friend friend,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: Colors.grey[200],
        child: Icon(Icons.person, color: Colors.grey[500], size: 30),
      ),
      title: Text(
        friend.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        friend.lastSeen,
        style: TextStyle(color: Colors.black, fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatHistoryScreen(friendName: friend.name),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
            tooltip: '채팅 기록',
          ),
          IconButton(
            // [수정] 통화 버튼 로직
            onPressed: () async {
              // 1. 서버에 통화 시작 요청 (friend.id 전송)
              String? sessionId = await ApiService.startCall(friend.id);

              if (!context.mounted) return;

              if (sessionId != null) {
                // 2. 성공 시 CallScreen으로 이동 (sessionId 전달)
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
                // 3. 실패 시 에러 메시지
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('통화 서버에 연결할 수 없습니다.')),
                );
              }
            },
            icon: const Icon(Icons.call, color: Colors.green),
            tooltip: '통화하기',
          ),
        ],
      ),
    );
  }
}