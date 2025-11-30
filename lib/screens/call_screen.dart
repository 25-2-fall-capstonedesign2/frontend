// lib/screens/call_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:anycall/api_service.dart';

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
  bool _isRecording = false;
  bool _isSending = false;

  // 시스템 준비 상태
  bool _isSystemReady = false;

  // 녹음기 해제 여부 플래그
  bool _isRecorderDisposed = false;

  // [송신] 녹음 데이터를 로컬에 모아둘 버퍼
  List<Uint8List> _audioBuffer = [];

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  // [수신] 오디오 재생을 위한 수동 큐(Queue)와 재생 상태 변수
  final List<Uint8List> _audioQueue = [];
  bool _isPlayingAudio = false;

  StreamSubscription<Uint8List>? _audioDataSubscription;
  StreamSubscription? _webSocketSubscription;

  static const int _sampleRate = 32000;
  static const int _numChannels = 1;

  @override
  void initState() {
    super.initState();
    _initializeAudioAndConnect();
  }

  Future<void> _initializeAudioAndConnect() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      const String wsHost = 'anycall.store';
      String wsUrl = 'wss://$wsHost/ws-client?sessionId=${widget.sessionId}';

      _channel = IOWebSocketChannel.connect(wsUrl);
      if (mounted) setState(() { _isConnected = true; });

      _webSocketSubscription = _channel!.stream.listen(
            (message) {
          if (message is List<int>) {
            print("📥 오디오 데이터 수신: ${message.length} bytes");

            // [재생 로직] 수신된 PCM 데이터에 헤더를 붙여 큐에 넣고 재생 처리
            final wavData = _addWavHeader(message);
            _audioQueue.add(wavData);
            _processAudioQueue();

          } else {
            print("서버 텍스트 메시지: $message");
            try {
              final data = jsonDecode(message);
              if (data['type'] == 'system' && data['event'] == 'ready') {
                if (mounted) {
                  setState(() {
                    _isSystemReady = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("AI 연결 완료! 대화를 시작하세요.")),
                  );
                }
              }
            } catch (e) {
              // JSON 파싱 에러 무시
            }
          }
        },
        onDone: () {
          print("WebSocket 연결이 종료되었습니다.");
          if (mounted) {
            setState(() { _isConnected = false; });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("서버와의 연결이 종료되었습니다.")),
            );
          }
        },
        onError: (error) {
          print('WebSocket 오류: $error');
          if (mounted) {
            setState(() { _isConnected = false; });
          }
        },
      );
    } catch (e) {
      print('WebSocket 연결 실패: $e');
    }
  }

  // [수정] 오디오 큐 처리 함수 (임시 파일 저장 후 재생)
  Future<void> _processAudioQueue() async {
    if (_isPlayingAudio || _audioQueue.isEmpty) return;

    if (mounted) {
      setState(() { _isPlayingAudio = true; });
    }

    try {
      while (_audioQueue.isNotEmpty) {
        final wavData = _audioQueue.removeAt(0);

        // 1. 임시 파일 생성 (고유한 이름 사용)
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav');

        // 2. 파일에 데이터 쓰기
        await tempFile.writeAsBytes(wavData);

        // 3. 파일 경로로 재생 (Data URI 대신 File Path 사용)
        await _player.setFilePath(tempFile.path);
        _player.play();

        // 4. 재생이 끝날 때까지 대기
        await _player.playerStateStream.firstWhere(
                (state) => state.processingState == ProcessingState.completed
        );

        // 5. 재생 완료 후 파일 삭제 (청소)
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (e) {
          print("임시 파일 삭제 실패: $e");
        }
      }
    } catch (e) {
      print("오디오 재생 중 오류: $e");
    } finally {
      setState(() { _isPlayingAudio = false; });
    }
  }

  // [수정됨] Raw PCM 데이터에 WAV 헤더를 추가하는 함수
  Uint8List _addWavHeader(List<int> pcmData) {
    var channels = 1;
    var sampleRate = 32000;
    var byteRate = 16 * sampleRate * channels ~/ 8;
    var dataSize = pcmData.length;
    var totalSize = 36 + dataSize;

    final header = Uint8List(44);
    final view = ByteData.view(header.buffer);

    // RIFF header
    header.setRange(0, 4, [82, 73, 70, 70]); // "RIFF"
    view.setUint32(4, totalSize, Endian.little);
    header.setRange(8, 12, [87, 65, 86, 69]); // "WAVE"

    // fmt subchunk
    header.setRange(12, 16, [102, 109, 116, 32]); // "fmt "
    view.setUint32(16, 16, Endian.little);
    view.setUint16(20, 1, Endian.little);
    view.setUint16(22, channels, Endian.little);
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, byteRate, Endian.little);
    view.setUint16(32, (channels * 16) ~/ 8, Endian.little);
    view.setUint16(34, 16, Endian.little);

    // data subchunk
    // [수정] 기존: setRange(36, 4, ...) -> 수정: setRange(36, 40, ...)
    // 시작 인덱스가 36이고 길이가 4이므로, 끝 인덱스는 40이어야 합니다.
    header.setRange(36, 40, [100, 97, 116, 97]); // "data"
    view.setUint32(40, dataSize, Endian.little);

    var wavFile = BytesBuilder();
    wavFile.add(header);
    wavFile.add(pcmData);
    return wavFile.toBytes();
  }

  void _startRecording() async {
    // 3. [수정] 준비되지 않았으면 시작 불가
    if (_isRecording || _isSending || !_isConnected || !_isSystemReady) return;

    _audioBuffer.clear();

    try {
      if (_isRecorderDisposed) return;

      _audioDataSubscription = (await _recorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: _sampleRate,
            numChannels: _numChannels,
          )
      )).listen((Uint8List audioChunk) {
        if (mounted) {
          _audioBuffer.add(audioChunk);
        }
      });

      if (mounted) setState(() { _isRecording = true; });
    } catch (e) {
      print("녹음 시작 실패: $e");
    }
  }

  void _sendAudio() async {
    if (!_isRecording || _isSending) return;

    // 녹음 중지 및 버퍼링 중지
    await _audioDataSubscription?.cancel();
    await _recorder.stop();

    if (mounted) {
      setState(() {
        _isRecording = false;
        _isSending = true; // 전송 로딩 시작
      });
    }

    // 오디오 청크들을 하나로 합침
    final totalLength = _audioBuffer.fold(0, (len, chunk) => len + chunk.length);
    final Uint8List fullAudioData = Uint8List(totalLength);
    int offset = 0;
    for (var chunk in _audioBuffer) {
      fullAudioData.setAll(offset, chunk);
      offset += chunk.length;
    }
    _audioBuffer.clear(); // 버퍼 메모리 해제

    // WebSocket 전송
    if (_isConnected) {
      // 1. 순수 음성 데이터만 전송
      _channel?.sink.add(fullAudioData);

      // [삭제] 서버가 텍스트를 받으면 연결을 끊으므로 이 줄은 삭제
      // _channel?.sink.add(jsonEncode({'type': 'vad', 'state': 'silence'}));
    }

    // 서버 응답 대기 (임시 지연)
    // 서버가 음성 데이터를 다 받으면 자동으로 처리를 시작
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isSending = false; // 전송 로딩 끝
      });
    }
  }


  Future<void> _handleHangUp({bool isRemote = false}) async {
    _audioQueue.clear();
    _isPlayingAudio = false;

    await _audioDataSubscription?.cancel();
    await _webSocketSubscription?.cancel();

    if (!_isRecorderDisposed) {
      _isRecorderDisposed = true;
      try {
        if (await _recorder.isRecording()) {
          await _recorder.stop();
        }
      } catch (e) {}
      try {
        _recorder.dispose();
      } catch (e) {}
    }

    try {
      await _player.stop();
      _player.dispose();
    } catch (e) {}

    try {
      _channel?.sink.close();
    } catch (e) {}

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
              Text(
                _isPlayingAudio
                    ? '상대방이 말하는 중이에요! 🔊' // 👈 1순위: 듣는 중
                    : (_isSending
                    ? 'AI 처리 중...'
                    : (!_isSystemReady
                    ? 'AI 준비 중...'
                    : (_isRecording ? '🔴 녹음 중' : (_isConnected ? '연결됨' : '연결 끊김')))),
                style: TextStyle(
                  // 듣는 중일 때는 파란색, 녹음 중일 때는 빨간색, 나머지는 흰색/회색
                    color: _isPlayingAudio
                        ? Colors.blueAccent
                        : (_isRecording ? Colors.redAccent : Colors.white70),
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                ),
              ),
              const Spacer(),

              const Spacer(flex: 2),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: (!_isSystemReady || _isRecording || _isSending || !_isConnected)
                        ? null
                        : _startRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (!_isSystemReady)
                          ? Colors.grey
                          : (_isRecording ? Colors.orange : Colors.green),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      !_isSystemReady
                          ? '준비 중...'
                          : (_isRecording ? '말하는 중...' : '말하기 시작'),
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),

                  ElevatedButton(
                    onPressed: _isRecording && !_isSending ? _sendAudio : null,
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