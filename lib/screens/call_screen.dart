// lib/screens/call_screen.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:anycall/api_service.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';

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

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  StreamController<Uint8List>? _audioDataController;
  StreamSubscription<Uint8List>? _audioDataSubscription;
  StreamSubscription? _webSocketSubscription;

  final int _sampleRate = 32000;
  final Codec _codec = Codec.pcm16;

  @override
  void initState() {
    super.initState();
    _initializeAudioAndConnect();
  }

  Future<void> _initializeAudioAndConnect() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    await _recorder.openRecorder();
    await _player.openPlayer();

    _audioDataController = StreamController<Uint8List>();
    _audioDataSubscription = _audioDataController!.stream.listen((Uint8List audioChunk) {
      if (audioChunk != null && _isConnected) {
        _channel?.sink.add(audioChunk);
      }
    });

    await _player.startPlayerFromStream(
      codec: _codec,
      numChannels: 1,
      sampleRate: _sampleRate,
      bufferSize: 4096,
      interleaved: false,
    );

    _connectWebSocket();
    _startStreamingAudio();
  }

  void _connectWebSocket() {
    try {
      // API 명세서 Base URL (https://anycall.store)에 맞춰 WSS 프로토콜 사용
      const String wsHost = 'anycall.store';
      String wsUrl = 'wss://$wsHost/ws-client?sessionId=${widget.sessionId}';

      _channel = IOWebSocketChannel.connect(wsUrl);
      setState(() { _isConnected = true; });

      _webSocketSubscription = _channel!.stream.listen(
            (message) {
          if (message is List<int>) {
            _player.feedUint8FromStream(Uint8List.fromList(message));
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

  void _startStreamingAudio() {
    _recorder.startRecorder(
      toStream: _audioDataController!.sink,
      codec: _codec,
      numChannels: 1,
      sampleRate: _sampleRate,
    );
  }

  Future<void> _handleHangUp({bool isRemote = false}) async {
    await _audioDataSubscription?.cancel();
    await _webSocketSubscription?.cancel();
    await _recorder.stopRecorder();
    await _player.stopPlayer();
    await _audioDataController?.close();
    _channel?.sink.close();

    setState(() { _isConnected = false; });

    if (!isRemote) {
      await ApiService.hangUp(widget.sessionId);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
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
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                widget.friendName,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _isConnected ? '연결됨' : '연결 중...',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () { /* TODO: 음소거 기능 */ },
                    icon: const Icon(Icons.mic_off, color: Colors.white, size: 30),
                  ),
                  IconButton(
                    onPressed: () => _handleHangUp(isRemote: false),
                    icon: const Icon(Icons.call_end, color: Colors.red, size: 40),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.all(15)
                    ),
                  ),
                  IconButton(
                    onPressed: () { /* TODO: 스피커폰 기능 */ },
                    icon: const Icon(Icons.volume_up, color: Colors.white, size: 30),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}