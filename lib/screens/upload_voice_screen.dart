// lib/screens/upload_voice_screen.dart

import 'dart:io';
import 'package:anycall/api_service.dart';
import 'package:anycall/screens/home_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class UploadVoiceScreen extends StatefulWidget {
  const UploadVoiceScreen({super.key});

  @override
  State<UploadVoiceScreen> createState() => _UploadVoiceScreenState();
}

class _UploadVoiceScreenState extends State<UploadVoiceScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _selectedFile; // 선택된 파일
  bool _isUploading = false; // 업로드 중 상태

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 파일 선택 함수
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'], // MP3만 허용
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  // 업로드 실행 함수
  Future<void> _handleUpload() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('목소리 이름을 입력해주세요.')));
      return;
    }
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('음성 파일을 선택해주세요.')));
      return;
    }

    setState(() { _isUploading = true; });

    // API 호출
    bool success = await ApiService.uploadVoiceProfile(name, _selectedFile!);

    setState(() { _isUploading = false; });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('목소리가 추가되었습니다!')));
        // 홈 화면으로 이동 (목록 갱신을 위해 모든 스택 지우고 이동하거나, pop 후 refresh)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('업로드에 실패했습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1740), // 요청하신 배경색
      appBar: AppBar(
        title: const Text('새로운 목소리 만들기'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        // 뒤로가기 버튼은 기본적으로 생성되지만, 명시적으로 홈으로 가고 싶다면 아래 주석 해제
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                '어떻게 목소리를 추가하시겠어요?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                '기존 오디오 파일을 업로드하여 목소리 모델을 만들 수 있습니다.',
                style: TextStyle(fontSize: 14, color: Colors.grey[400], height: 1.5),
              ),
              const SizedBox(height: 30),

              // 1. 이름 입력 필드
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '목소리 이름',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.edit, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              // 2. 파일 업로드 카드 (선택됨 표시)
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _selectedFile != null ? Colors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedFile != null ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '음성 샘플 업로드 (MP3)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Icon(Icons.cloud_upload_outlined, color: Colors.grey[400]),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // 파일 선택 시 파일명 표시
                      if (_selectedFile != null)
                        Text(
                          "선택된 파일: ${_selectedFile!.path.split('/').last}",
                          style: const TextStyle(color: Colors.greenAccent),
                        )
                      else
                      // 프로그레스 바 디자인 (장식용)
                        LinearProgressIndicator(
                          value: 0,
                          backgroundColor: Colors.grey[700],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. 음성 녹음 카드 (기능 미구현 - 비활성화 느낌)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05), // 더 어둡게 처리
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '음성 녹음 (준비중)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                        ),
                        Icon(Icons.mic, color: Colors.grey[700]),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: 0,
                      backgroundColor: Colors.grey[800],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 4. 하단 계속하기(업로드) 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _handleUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black, // 텍스트 색상
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator()
                      : const Text(
                    '업로드 하기',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}