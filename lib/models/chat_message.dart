class ChatMessage {
  final String sender; // "USER" 또는 "AI"
  final String content;
  final String timestamp;

  ChatMessage({required this.sender, required this.content, required this.timestamp});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'],
      content: json['content'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}