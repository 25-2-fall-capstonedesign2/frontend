// lib/screens/call_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:anycall/api_service.dart';

// [패키지] record와 just_audio를 사용합니다.
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

class CallScreen extends StatefulWidget {
  final String friendName;
  final String sessionId;

  const CallScreen({
    super.key,
    required this.friendName,
    required this.sessionId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  IOWebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isRecording = false; // 녹음 상태
  bool _isSending = false; // 전송/AI 처리 중 상태

  // [오디오 인스턴스]
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  // [순수 이진 데이터 버퍼] 녹음 데이터를 로컬에 임시 저장할 버퍼
  List<Uint8List> _audioBuffer = [];

  StreamSubscription<Uint8List>? _audioDataSubscription;
  StreamSubscription? _webSocketSubscription;

  // [서버 명세] 32kHz, 16bit PCM
  static const int _sampleRate = 32000;
  static const int _numChannels = 1;

  @override
  void initState() {
    super.initState();
    _initializeAudioAndConnect();
  }

  // 1. 오디오 초기화 및 WebSocket 연결
  Future<void> _initializeAudioAndConnect() async {
    // [권한 체크] record가 권한을 요청하고 승인되지 않으면 종료
    if (!await _recorder.hasPermission()) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // [자원 열기]
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      // WSS 주소 (anycall.store) 사용
      const String wsHost = 'anycall.store';
      String wsUrl = 'wss://$wsHost/ws-client?sessionId=${widget.sessionId}';

      _channel = IOWebSocketChannel.connect(wsUrl);
      if (mounted) setState(() { _isConnected = true; });

      _webSocketSubscription = _channel!.stream.listen(
            (message) {
          // 2. [수신 및 재생] 서버에서 AI 응답을 받으면 재생
          if (message is List<int>) {
            _player.setAudioSource(AudioSource.uri(
              Uri.dataFromBytes(Uint8List.fromList(message), mimeType: 'audio/pcm'),
            ));
            _player.play();
          } else {
            print("서버 텍스트 메시지: $message");
          }
        },
        onDone: () => _handleHangUp(isRemote: true),
        onError: (error) {
          print('WebSocket 오류: $error');
          _handleHangUp(isRemote: true);
        },
      );
    } catch (e) {
      print('WebSocket 연결 실패: $e');
    }
  }

  // 3. [녹음 시작] 함수
  void _startRecording() async {
    if (_isRecording || _isSending || !_isConnected) return;

    _audioBuffer.clear(); // 이전 녹음 데이터 초기화

    // [Fix] Future<Stream>을 await로 기다렸다가 .listen을 호출해야 합니다.
    _audioDataSubscription = (await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits, // Raw PCM 16bit (오류 해결)
          sampleRate: _sampleRate,
          numChannels: _numChannels,
        )
    )).listen((Uint8List audioChunk) { // StreamSubscription<Uint8List>에 할당
      if (mounted) {
        _audioBuffer.add(audioChunk); // 로컬 버퍼에 저장
      }
    });

    if (mounted) setState(() { _isRecording = true; });
  }

  // 4. [보내기/전송] 함수
  void _sendAudio() async {
    if (!_isRecording || _isSending) return;

    // 녹음 중지 및 버퍼링 중지
    await _audioDataSubscription?.cancel();
    await _recorder.stop();

    if (mounted) setState(() {
      _isRecording = false;
      _isSending = true; // 전송 로딩 시작
    });

    // 오디오 청크들을 하나로 합침
    final totalLength = _audioBuffer.fold(0, (len, chunk) => len + chunk.length);
    final Uint8List fullAudioData = Uint8List(totalLength);
    int offset = 0;
    for (var chunk in _audioBuffer) {
      fullAudioData.setAll(offset, chunk);
      offset += chunk.length;
    }
    _audioBuffer.clear();

    // WebSocket 전송 및 VAD 신호 전송
    if (_isConnected) {
      _channel?.sink.add(fullAudioData);
      _channel?.sink.add(jsonEncode({'type': 'vad', 'state': 'silence'}));
    }

    // 서버 응답 대기 (임시 지연)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) setState(() {
      _isSending = false; // 전송 로딩 끝
    });
  }


  Future<void> _handleHangUp({bool isRemote = false}) async {
    // 자원 해제 로직
    await _audioDataSubscription?.cancel();
    await _webSocketSubscription?.cancel();
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    _recorder.dispose();
    _player.dispose();

    _channel?.sink.close();

    if (mounted) setState(() { _isConnected = false; });

    if (!isRemote) {
      await ApiService.hangUp(widget.sessionId);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _handleHangUp();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 20),
              Text(
                widget.friendName,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // [상태 표시]
              Text(
                _isSending
                    ? 'AI 처리 중...'
                    : (_isRecording ? '🔴 녹음 중' : (_isConnected ? '연결됨' : '연결 끊김')),
                style: TextStyle(
                    color: _isRecording ? Colors.redAccent : Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                ),
              ),
              const Spacer(),

              const Spacer(flex: 2),

              // --- 버튼 UI ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 1. 말하기 버튼 (녹음 시작)
                  ElevatedButton(
                    onPressed: (_isRecording || _isSending || !_isConnected) ? null : _startRecording, // 연결 안되면 비활성화
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      '말하기 시작',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),

                  // 2. 보내기 버튼 (음성 전송)
                  ElevatedButton(
                    onPressed: _isRecording && !_isSending ? _sendAudio : null, // 녹음 중일 때만 활성화
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRecording ? Colors.blue : Colors.grey,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSending
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('보내기', style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // 3. 통화 종료 버튼
              IconButton(
                onPressed: () => _handleHangUp(isRemote: false),
                icon: const Icon(Icons.call_end, color: Colors.white, size: 40),
                style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.all(15)
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}