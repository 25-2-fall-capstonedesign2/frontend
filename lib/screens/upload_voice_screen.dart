// lib/screens/upload_voice_screen.dart

import 'dart:io'; // 파일 처리를 위해 필요
import 'package:anycall/api_service.dart';
import 'package:anycall/screens/home_screen.dart';
import 'package:file_picker/file_picker.dart'; // 파일 선택 패키지
import 'package:flutter/material.dart';

class UploadVoiceScreen extends StatefulWidget {
  const UploadVoiceScreen({super.key});

  @override
  State<UploadVoiceScreen> createState() => _UploadVoiceScreenState();
}

class _UploadVoiceScreenState extends State<UploadVoiceScreen> {
  final TextEditingController _nameController = TextEditingController();

  // 선택된 파일 정보를 저장할 변수
  File? _selectedFile;
  String? _fileName;

  // 업로드 진행 상태
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 1. [파일 선택 기능] 구름 버튼 클릭 시 실행
  Future<void> _pickFile() async {
    // 파일 선택기 실행
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'], // MP3 파일만 허용
    );

    if (result != null) {
      // 파일을 선택했을 경우 상태 업데이트
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    } else {
      // 사용자가 취소한 경우
      print("파일 선택 취소");
    }
  }

  // 2. [업로드 기능] 계속하기 버튼 클릭 시 실행
  Future<void> _handleUpload() async {
    final name = _nameController.text.trim();

    // 유효성 검사
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('목소리 이름을 입력해주세요.')));
      return;
    }
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('음성 파일(MP3)을 업로드해주세요.')));
      return;
    }

    setState(() { _isUploading = true; });

    // 백엔드로 전송 (api_service.dart의 uploadVoiceProfile 함수 호출)
    bool success = await ApiService.uploadVoiceProfile(name, _selectedFile!);

    setState(() { _isUploading = false; });

    if (!mounted) return;

    if (success) {
      // 성공 시 홈 화면으로 이동 (스택 비우기)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('목소리가 성공적으로 등록되었습니다!')));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('업로드 실패. 다시 시도해주세요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1740),
      appBar: AppBar(
        title: const Text('새로운 목소리 만들기'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView( // 키보드 올라옴 방지
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
                    labelText: '목소리 이름', // 예: 홍길동
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

                // 2. [핵심] 파일 업로드 영역 (클릭 가능하도록 GestureDetector 사용)
                GestureDetector(
                  onTap: _pickFile, // 클릭 시 파일 선택창 열기
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      // 파일이 선택되면 배경색을 약간 다르게 표시
                      color: _selectedFile != null
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        // 파일이 선택되면 파란 테두리
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
                            // 파일 선택 여부에 따라 아이콘 변경
                            Icon(
                                _selectedFile != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                                color: _selectedFile != null ? Colors.blue : Colors.grey[400]
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // 파일 선택 상태 표기
                        if (_selectedFile != null) ...[
                          Row(
                            children: [
                              const Icon(Icons.audio_file, color: Colors.white70, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _fileName ?? "선택된 파일",
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          const LinearProgressIndicator( // 파일 선택됨 표시 (100%)
                            value: 1.0,
                            backgroundColor: Colors.grey,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                          const SizedBox(height: 5),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text("준비 완료", style: TextStyle(color: Colors.blue, fontSize: 12)),
                          )
                        ] else ...[
                          // 파일 선택 전 (빈 프로그레스 바)
                          LinearProgressIndicator(
                            value: 0,
                            backgroundColor: Colors.grey[700],
                          ),
                          const SizedBox(height: 5),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text("0%", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          )
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. 음성 녹음 카드 (비활성화 상태 UI 유지)
                Opacity( // 약간 흐리게 처리
                  opacity: 0.5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
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
                        const SizedBox(height: 15),
                        LinearProgressIndicator(
                          value: 0,
                          backgroundColor: Colors.grey[800],
                        ),
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text("0%", style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40), // 하단 여백 확보

                // 4. 업로드 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _handleUpload, // 업로드 중 클릭 방지
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: _isUploading
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text("업로드 중...", style: TextStyle(fontSize: 16)),
                      ],
                    )
                        : const Text(
                      '계속하기', // 또는 '업로드 하기'
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}