// lib/screens/home_screen.dart

import 'package:anycall/screens/login_screen.dart';
import 'package:anycall/screens/call_screen.dart';
import 'package:anycall/screens/chat_history_screen.dart';
import 'package:anycall/api_service.dart';
import 'package:anycall/models/voice_profile.dart'; // VoiceProfile 모델 import 필수
import 'package:flutter/material.dart';

// Friend 클래스 (UI용 데이터 모델)
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

    // 1. [수정] 타입 불일치 해결: List<String>이 아닌 List<VoiceProfile>로 받음
    List<VoiceProfile> profiles = [];

    try {
      // 목소리 프로필 목록 조회 (getVoiceProfiles 사용)
      profiles = await ApiService.getVoiceProfiles();

      // 사용자 이름 조회 (옵션)
      // String? name = await ApiService.getUserName();
      // fetchedUserName = name ?? "사용자";
    } catch (e) {
      print("데이터 로드 중 오류 발생: $e");
    }

    if (mounted) {
      setState(() {
        _userName = fetchedUserName;

        // 2. [수정] VoiceProfile 데이터를 Friend 객체로 변환
        _allFriends = profiles.map((profile) => Friend(
          name: profile.profileName, // VoiceProfile의 profileName을 사용
          status: '통화가능',
          statusColor: Colors.blueGrey,
          lastSeen: '터치하여 통화 또는 대화 기록 열람',
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
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_outlined),
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
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        friend.lastSeen,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // 3. [수정] ChatHistoryScreen은 friendName을 받도록 수정됨
                  // 기존: builder: (context) => ChatHistoryScreen(friend: friend), (X)
                  // 수정: builder: (context) => ChatHistoryScreen(friendName: friend.name), (O)
                  builder: (context) => ChatHistoryScreen(friendName: friend.name),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
            tooltip: '채팅 기록',
          ),
          IconButton(
            onPressed: () async {
              String? sessionId = await ApiService.startCall(friend.name);

              if (!context.mounted) return;

              if (sessionId != null) {
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